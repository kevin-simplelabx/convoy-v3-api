# One person who signs in to the Convoy Driver app, by mobile number (one-time code). Platform-wide: the profile belongs
# to the person and travels with them; each transport company keeps its own record of them (an own driver or an operator
# driver), linked here by mobile number. Those records are the memberships: pending = an invitation, active = working
# for that company, past = left (Employment History).
# == Schema Information
#
# Table name: driver_accounts
# Database name: primary
#
#  id                   :bigint           not null, primary key
#  address              :text
#  date_of_birth        :date
#  email                :string
#  encrypted_password   :string           default(""), not null
#  id_number            :text
#  id_number_masked     :string
#  last_sign_in_at      :datetime
#  name                 :string
#  nationality          :string
#  password_set_at      :datetime
#  phone                :string           not null
#  phone_verified_at    :datetime
#  photo                :string
#  postal_code          :string
#  residential_status   :string
#  singpass_fields      :string           default([]), not null, is an Array
#  singpass_verified_at :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_driver_accounts_on_email  (email) UNIQUE WHERE (email IS NOT NULL)
#  index_driver_accounts_on_phone  (phone) UNIQUE
#
class DriverAccount < ApplicationRecord
  RESIDENTIAL_STATUSES = [ "Singapore Citizen", "Permanent Resident", "Employment Pass", "S Pass", "Work Permit", "Other" ].freeze
  # Personal Details the driver can fill in; the ones Singpass verified (singpass_fields) are locked.
  PROFILE_FIELDS = %w[name date_of_birth nationality residential_status id_number address postal_code].freeze

  devise :database_authenticatable, :jwt_authenticatable, jwt_revocation_strategy: Devise::JWT::RevocationStrategies::Null

  audited except: %i[encrypted_password id_number last_sign_in_at]

  mount_uploader :photo, ImageUploader
  encrypts :id_number

  has_many :drivers, dependent: :nullify
  has_many :operator_drivers, dependent: :nullify
  has_many :jwts, class_name: "DriverJwt", dependent: :delete_all
  has_many :licences, -> { order(:created_at, :id) }, class_name: "DriverLicence", dependent: :destroy, inverse_of: :driver_account

  normalizes :phone, with: PhoneNormalizer
  normalizes :email, with: ->(v) { v.to_s.strip.downcase.presence }
  normalizes :name, with: ->(v) { v.to_s.squish.presence }

  validates :phone, presence: true, uniqueness: true, phone: { possible: true, allow_blank: true }
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :password, length: { within: Devise.password_length, message: "needs at least 8 characters" }, confirmation: true, allow_nil: true
  validates :residential_status, inclusion: { in: RESIDENTIAL_STATUSES }, allow_nil: true
  validates :postal_code, format: { with: /\A\d{6}\z/, message: "must be 6 digits" }, allow_blank: true
  validate :date_of_birth_in_past

  normalizes :id_number, with: ->(v) { v.to_s.gsub(/\s+/, "").upcase.presence }
  before_save { self.id_number_masked = DriverKycProfile.mask(id_number) if id_number_changed? }

  def password_set? = password_set_at.present?

  def singpass_verified? = singpass_verified_at.present?

  def locked_fields = singpass_verified? ? singpass_fields : []

  # FIN for pass holders, else NRIC.
  def id_label = residential_status.to_s.match?(/work permit|employment pass|s pass/i) ? "FIN" : "NRIC"

  # Address as one line, with the postal code: "Blk 310 Tampines St 33 #07-114, Singapore 520310".
  def full_address = [ address, postal_code && "Singapore #{postal_code}" ].compact_blank.join(", ").presence

  # Complete My Profile: what companies check before they send trips.
  def completeness
    items = {
      phone: phone_verified_at.present?,
      name: name.present?,
      date_of_birth: date_of_birth.present?,
      email_password: email.present? && password_set?,
      licences: licences.any? { it.kind == "dl" && it.classes.present? } && licences.any? { it.kind == "vl" && it.classes.present? },
      photo: photo.present?
    }
    { done: items.count { _2 }, total: items.size, items: items.map { |key, done| { key:, done: } } }
  end

  def phone_display = Phonelib.parse(phone).then { |p| p.valid? ? p.international : phone }

  # Every company record of this person that the app shows: invitations, current and past companies (not declined
  # or deleted), in any company. with: more associations to preload.
  def memberships(with: [])
    ActsAsTenant.without_tenant do
      [ drivers, operator_drivers ].flat_map do |scope|
        scope.kept.where(status: %w[pending active past]).includes(:company, *with, *(scope.klass == OperatorDriver ? [ :operator ] : [])).to_a
      end.sort_by { |m| [ DriverMembership::ORDER.index(m.status), m.company.name ] }
    end
  end

  # The membership with this key ("driver-4", "operator_driver-2"), or nil.
  def membership(key) = memberships.find { |m| DriverMembership.key(m) == key.to_s }

  # Company records with this mobile number not yet linked to anyone: they become this person's.
  def link_memberships!
    ActsAsTenant.without_tenant do
      [ Driver, OperatorDriver ].each { |klass| klass.kept.where(phone:, driver_account_id: nil).update_all(driver_account_id: id) } # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # Active company records: the companies that see this profile (their copy is kept after the driver leaves).
  def active_memberships(with: []) = memberships(with:).select(&:active?)

  # The account for a mobile number, created on first sign-in.
  def self.for_phone!(phone)
    find_or_create_by!(phone: normalize_value_for(:phone, phone))
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  def date_of_birth_in_past
    errors.add(:date_of_birth, "must be in the past") if date_of_birth && date_of_birth >= Date.current
  end
end
