# == Schema Information
#
# Table name: companies
# Database name: primary
#
#  id                        :bigint           not null, primary key
#  business_units_enabled    :boolean          default(FALSE), not null
#  code                      :string(6)        not null
#  country                   :string           default("SG"), not null
#  date_format               :string           default("dmy"), not null
#  external_vehicle_cap      :integer          default(10), not null
#  logo                      :string
#  name                      :string           not null
#  observed_holidays         :string           default("off"), not null
#  on_time_minutes           :integer          default(5), not null
#  route_list_import_enabled :boolean          default(TRUE), not null
#  school_run_enabled        :boolean          default(TRUE), not null
#  short_name                :string(12)
#  speed_limit_kmh           :integer          default(80), not null
#  status                    :string           default("active"), not null
#  theme_color               :string
#  time_format               :string           default("24"), not null
#  timezone                  :string           default("Asia/Singapore"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
# Indexes
#
#  index_companies_on_code  (code) UNIQUE
#
# A transport company: the tenant. Every company-owned record belongs to one.
class Company < ApplicationRecord
  DATE_FORMATS = %w[dmy mdy ymd dmon].freeze
  TIME_FORMATS = %w[24 12].freeze
  COUNTRIES = %w[SG TW MY TH HK].freeze

  mount_uploader :logo, ImageUploader

  include SyncsOccurrences

  has_many :users, dependent: :restrict_with_error

  # Observed Holidays Day Off / Working Day for trips without a calendar.
  after_update_commit if: :saved_change_to_observed_holidays? do
    ActsAsTenant.with_tenant(self) { resync_occurrences(Trip.kept.recurring.where(calendar_id: nil, skip_public_holidays: true)) }
  end

  enum :status, { active: "active", suspended: "suspended" }, validate: true
  enum :observed_holidays, { off: "off", work: "work" }, prefix: :observed, validate: true

  normalizes :code, with: ->(v) { v.to_s.strip.upcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z0-9]{2,6}\z/ }
  validates :short_name, length: { maximum: 12 }
  validates :country, inclusion: { in: COUNTRIES }
  validates :date_format, inclusion: { in: DATE_FORMATS }
  validates :time_format, inclusion: { in: TIME_FORMATS }
  validates :timezone, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values.uniq | TZInfo::Timezone.all_identifiers }
  validates :theme_color, format: { with: /\A#\h{6}\z/ }, allow_blank: true
  validates :external_vehicle_cap, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth = nil) = %w[name code country status]

  DATE_PATTERNS = { "dmy" => "%d/%m/%Y", "mdy" => "%m/%d/%Y", "ymd" => "%Y-%m-%d", "dmon" => "%-d %b %Y" }.freeze

  # A date in the company's Date Format (messages written by the server; the front end formats its own).
  def format_date(date) = date&.strftime(DATE_PATTERNS.fetch(date_format))

  # A time of day (minutes) in the company's Time Format.
  def format_time(minutes)
    return nil if minutes.nil?
    return Clock.hm(minutes) if time_format == "24"

    m = minutes % 1440
    format("%d:%02d %s", ((m / 60) % 12).nonzero? || 12, m % 60, m < 720 ? "am" : "pm")
  end
end
