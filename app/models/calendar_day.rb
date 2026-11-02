# == Schema Information
#
# Table name: calendar_days
# Database name: primary
#
#  id             :bigint           not null, primary key
#  ends_on        :date             not null
#  in_place_of    :date
#  kind           :string           not null
#  label          :string
#  new_time       :integer
#  notify_drivers :boolean          default(FALSE), not null
#  shift_minutes  :integer
#  starts_on      :date             not null
#  usual_time     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  calendar_id    :bigint           not null
#  company_id     :bigint           not null
#
# Indexes
#
#  index_calendar_days_on_calendar_id                            (calendar_id)
#  index_calendar_days_on_calendar_id_and_starts_on_and_ends_on  (calendar_id,starts_on,ends_on)
#  index_calendar_days_on_company_id                             (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (calendar_id => calendars.id)
#  fk_rails_...  (company_id => companies.id)
#
# One entry on a calendar: a single day or a range. Times are minutes after midnight.
class CalendarDay < ApplicationRecord
  include TenantScoped
  audited associated_with: :calendar
  include MinuteTime

  SCHOOL_KINDS = %w[hol ns early late].freeze
  GENERAL_KINDS = %w[off shift oil work].freeze
  NAMES = { "hol" => "School Holiday", "ns" => "No School", "early" => "Early Dismissal", "late" => "Late Arrival",
            "off" => "Day Off", "oil" => "Off in Lieu", "work" => "Working Holiday", "shift" => "Changed Times" }.freeze
  # Kinds on which trips do not run.
  OFF_KINDS = %w[hol ns off oil].freeze

  include SyncsOccurrences

  belongs_to :calendar, inverse_of: :days

  # Trips that follow the calendar run, stop or move on the days changed.
  after_commit do
    dates = [ starts_on, ends_on, starts_on_before_last_save, ends_on_before_last_save ].compact
    resync_occurrences(Trip.kept.where(calendar_id:), from: dates.min, to: dates.max,
                       routes: SchoolRoute.joins(plan: :school).where(schools: { calendar_id: }).pluck(:id))
  end

  enum :kind, NAMES.keys.index_by(&:itself), validate: true
  minute_time :usual_time, :new_time

  before_validation { self.ends_on ||= starts_on }

  validates :starts_on, :ends_on, presence: true
  validates :ends_on, comparison: { greater_than_or_equal_to: :starts_on }, if: -> { starts_on && ends_on }
  validate :kind_fits_calendar
  validates :usual_time, :new_time, presence: true, numericality: { in: 0...1440 }, if: -> { early? || late? }
  validates :shift_minutes, presence: true, numericality: { other_than: 0, in: -720..720 }, if: :shift?

  scope :overlapping, ->(from, to) { where("starts_on <= ? AND ends_on >= ?", to, from) }

  def kind_name = NAMES[kind]
  def off? = OFF_KINDS.include?(kind)

  # Minutes trips move on this day: new minus usual time (early / late), or the shift.
  def time_change
    return shift_minutes.to_i if shift?
    return new_time - usual_time if (early? || late?) && new_time && usual_time

    0
  end

  private

  def kind_fits_calendar
    allowed = calendar&.school? ? SCHOOL_KINDS : GENERAL_KINDS
    errors.add(:kind, "is not used on a #{calendar.kind} calendar") if calendar && allowed.exclude?(kind)
  end
end
