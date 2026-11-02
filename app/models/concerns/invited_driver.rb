# Shared by own drivers (Driver) and drivers of managed operators (OperatorDriver): invited with a name and mobile,
# they answer in the Convoy Driver app (an admin records the answer for now).
#   pending  → active (accept) | declined (decline)
#   active   → past (remove)
#   declined, past → pending (invite again)
# The mobile is stored in E.164 (+6591234567) and can only change while the invite is pending; it is unique among
# drivers who are pending or active. Each send is kept in driver_invites (SMS recorded, not sent yet).
module InvitedDriver
  extend ActiveSupport::Concern

  STATUSES = %w[pending active declined past].freeze

  included do
    include AASM
    include Discard::Model

    mount_uploader :photo, ImageUploader
    mount_uploader :display_photo, ImageUploader

    belongs_to :last_vehicle, class_name: "Vehicle", optional: true
    belongs_to :display_set_by, class_name: "User", optional: true
    has_many :invites, -> { order(:created_at) }, as: :invitable, class_name: "DriverInvite", dependent: :destroy
    has_one :kyc_profile, as: :driver, class_name: "DriverKycProfile", dependent: :destroy

    enum :status, STATUSES.index_by(&:itself), validate: true

    aasm column: :status, enum: true, whiny_persistence: true do
      state :pending, initial: true
      state :active, :declined, :past

      event(:accept) { transitions from: :pending, to: :active, after: :mark_responded }
      event(:decline) { transitions from: :pending, to: :declined, after: :mark_responded }
      event(:remove) { transitions from: :active, to: :past, after: :mark_responded }
      event(:reinvite) { transitions from: %i[declined past], to: :pending, after: :mark_invited }
    end

    normalizes :phone, with: ->(v) { Phonelib.parse(v).then { |p| p.valid? ? p.e164 : v.to_s.gsub(/[^\d+]/, "") } }

    validates :name, :phone, presence: true
    validates :phone, phone: { possible: true, allow_blank: true }
    validate :phone_unique_while_live
    validate :phone_locked, on: :update

    before_create { self.invited_at ||= Time.current }

    scope :live, -> { kept.where(status: %w[pending active]) }
  end

  # Tab counts: { pending:, active:, declined:, past: } (every tab present).
  class_methods do
    def tab_counts = STATUSES.index_with(0).merge(kept.group(:status).count).symbolize_keys
  end

  # Customer-facing copy set by the company: { name, photo } or nil to clear.
  def set_display!(name:, photo:, remove_photo:, user:)
    self.display_name = name.to_s.strip.presence
    self.display_photo = photo if photo.present?
    remove_display_photo! if ActiveModel::Type::Boolean.new.cast(remove_photo)
    clear = display_name.nil? && display_photo.blank?
    assign_attributes(display_set_by: clear ? nil : user, display_set_at: clear ? nil : Time.current)
    save!
  end

  def phone_display = Phonelib.parse(phone).then { |p| p.valid? ? p.international : phone }

  # Record an invite (or a resend) to the driver's mobile.
  def record_invite!(kind:, user:, message:)
    invites.create!(company_id:, kind:, phone:, message:, sent_by: user)
  end

  private

  def mark_responded = self.responded_at = Time.current

  def mark_invited
    self.invited_at = Time.current
    self.responded_at = nil
  end

  def phone_unique_while_live
    return if phone.blank? || discarded? || !(pending? || active?)

    dup = self.class.live.where(phone:).where.not(id:).first
    errors.add(:phone, :taken, message: "is already used by #{dup.name}") if dup
  end

  def phone_locked
    errors.add(:phone, "can only be changed by the driver in the Convoy Driver app") if phone_changed? && status_was != "pending"
  end
end
