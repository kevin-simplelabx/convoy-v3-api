# == Schema Information
#
# Table name: notices
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  all_runs           :boolean          default(TRUE), not null
#  audience           :string           default("trip"), not null
#  banner             :boolean          default(TRUE), not null
#  ended_at           :datetime
#  ends_at            :datetime         not null
#  message            :string(300)      not null
#  push               :boolean          default(FALSE), not null
#  sms                :boolean          default(FALSE), not null
#  starts_at          :datetime         not null
#  to_parents         :boolean          default(FALSE), not null
#  to_riders          :boolean          default(TRUE), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  company_id         :bigint           not null
#  created_by_id      :bigint
#  ended_by_id        :bigint
#  notice_template_id :bigint
#  school_id          :bigint
#  trip_id            :bigint
#
# Indexes
#
#  index_notices_on_company_id                            (company_id)
#  index_notices_on_company_id_and_starts_at_and_ends_at  (company_id,starts_at,ends_at)
#  index_notices_on_created_by_id                         (created_by_id)
#  index_notices_on_ended_by_id                           (ended_by_id)
#  index_notices_on_notice_template_id                    (notice_template_id)
#  index_notices_on_trip_id                               (trip_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (ended_by_id => users.id)
#  fk_rails_...  (notice_template_id => notice_templates.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (trip_id => trips.id)
#
# A banner or message to a trip's riders and / or parents for a period (Send Notice from the trip drawer).
# Delivered as an In-App Banner, Push or SMS; WhatsApp is not available yet. Push and SMS sends are recorded only.
class Notice < ApplicationRecord
  include TenantScoped
  audited

  MAX_MESSAGE = 300
  PLACEHOLDERS = /\{(min|time)\}/

  belongs_to :trip, optional: true
  belongs_to :school, optional: true
  has_many :route_targets, class_name: "NoticeRoute", dependent: :delete_all, inverse_of: :notice, autosave: true
  belongs_to :notice_template, optional: true
  belongs_to :ended_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :runs, class_name: "NoticeRun", dependent: :delete_all, inverse_of: :notice
  has_many :deliveries, class_name: "NoticeDelivery", dependent: :delete_all

  enum :audience, { trip: "trip", school: "school" }, prefix: :for, validate: true

  validates :trip, presence: { message: "must be picked" }, if: :for_trip?
  validates :school, presence: { message: "must be picked" }, if: :for_school?
  validates :starts_at, :ends_at, presence: true
  validates :ends_at, comparison: { greater_than: :starts_at, message: "must be after the start" }, if: -> { starts_at && ends_at }
  validates :message, presence: true, length: { maximum: MAX_MESSAGE }
  validate { errors.add(:base, "Pick who the notice is for") unless to_riders? || to_parents? }
  validate { errors.add(:base, "Pick at least one delivery channel") unless banner? || push? || sms? }
  validate { errors.add(:message, "still has #{message[PLACEHOLDERS]} to fill in") if message.to_s.match?(PLACEHOLDERS) }

  STATES = %w[active scheduled ended].freeze

  scope :active_at, ->(t) { where(ended_at: nil).where("starts_at <= :t AND ends_at > :t", t:) }
  scope :scheduled_at, ->(t) { where(ended_at: nil).where("starts_at > ?", t) }
  scope :ended_at_time, ->(t) { where("notices.ended_at IS NOT NULL OR notices.ends_at <= ?", t) }
  scope :in_state, lambda { |state, t|
    case state.to_s
    when "active" then active_at(t)
    when "scheduled" then scheduled_at(t)
    when "ended" then ended_at_time(t)
    else all
    end
  }
  # Notices page search: the message, or the audience (trip, client, Service For, school).
  scope :search, lambda { |q|
    next all if q.blank?

    left_joins(:school, trip: :client).where(
      "notices.message ILIKE :q OR trips.title ILIKE :q OR trips.service_for ILIKE :q OR clients.name ILIKE :q OR schools.name ILIKE :q",
      q: "%#{sanitize_sql_like(q.to_s.strip)}%"
    )
  }

  before_destroy :refuse_active, prepend: true

  # scheduled | active | ended
  def state(now = Time.current)
    return "ended" if ended_at || ends_at <= now

    starts_at > now ? "scheduled" : "active"
  end

  # Is the notice for this run (all timings, or this one)?
  def covers_run?(trip_run_id) = all_runs? || runs.any? { |r| r.trip_run_id == trip_run_id }

  # School routes: every route of the school, or the ones picked.
  def covers_route?(route_id) = all_runs? || route_targets.any? { |r| r.school_route_id == route_id }

  private

  def refuse_active
    return unless state == "active"

    errors.add(:base, "An active notice can't be deleted. End it first")
    throw :abort
  end
end
