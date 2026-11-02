# HR > Pay Schemes: how a driver is paid each month (see Pay::Engine for the rules). One scheme per company is the
# default: new drivers and drivers with no scheme assignment are paid on it.
# == Schema Information
#
# Table name: pay_schemes
# Database name: primary
#
#  id                           :bigint           not null, primary key
#  basic_cover_ph               :boolean          default(FALSE), not null
#  basic_covered_daily_trips    :integer          default(1), not null
#  basic_covered_schedule       :string           default("mon-fri"), not null
#  basic_covers_daily_trips     :boolean          default(FALSE), not null
#  basic_salary                 :decimal(12, 2)   default(0.0), not null
#  daily_volume_in_guarantee    :boolean          default(FALSE), not null
#  description                  :string
#  discarded_at                 :datetime
#  disposal_counts_as_trips     :boolean          default(FALSE), not null
#  guaranteed_amount            :decimal(12, 2)   default(2200.0), not null
#  has_daily_volume_incentive   :boolean          default(FALSE), not null
#  has_guarantee                :boolean          default(FALSE), not null
#  has_monthly_target_incentive :boolean          default(FALSE), not null
#  has_post_guarantee_boost     :boolean          default(FALSE), not null
#  has_rejection_penalty        :boolean          default(FALSE), not null
#  has_weekly_target_incentive  :boolean          default(FALSE), not null
#  is_default                   :boolean          default(FALSE), not null
#  locked_at                    :datetime
#  monthly_cover_ph             :boolean          default(FALSE), not null
#  monthly_daily_trips          :integer          default(6), not null
#  monthly_minimum_type         :string           default("daily"), not null
#  monthly_pay_amount           :decimal(12, 2)   default(2200.0), not null
#  monthly_schedule             :string           default("mon-fri"), not null
#  monthly_target_in_guarantee  :boolean          default(FALSE), not null
#  monthly_trips                :integer          default(150), not null
#  name                         :string           not null
#  on_top_ph                    :boolean          default(FALSE), not null
#  on_top_sat                   :boolean          default(FALSE), not null
#  on_top_sun                   :boolean          default(FALSE), not null
#  post_guarantee_boost_type    :string           default("percentage"), not null
#  post_guarantee_boost_value   :decimal(12, 2)   default(50.0), not null
#  rejection_allowed_jobs       :integer          default(0), not null
#  rejection_fallback_basic     :decimal(12, 2)   default(0.0), not null
#  rejection_keeps_incentives   :boolean          default(TRUE), not null
#  scheme_type                  :string           default("basic_plus_trips"), not null
#  school_routes_count          :boolean          default(FALSE), not null
#  school_routes_in_guarantee   :boolean          default(TRUE), not null
#  school_routes_pay            :boolean          default(FALSE), not null
#  shift_end_time               :integer          default(1080), not null
#  shift_overtime_hourly_rate   :decimal(12, 2)   default(0.0), not null
#  shift_overtime_pay_type      :string           default("trip_rates"), not null
#  shift_salary                 :decimal(12, 2)   default(0.0), not null
#  shift_start_time             :integer          default(480), not null
#  shift_working_days           :string           default(["mon", "tue", "wed", "thu", "fri"]), not null, is an Array
#  weekly_target_in_guarantee   :boolean          default(FALSE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  company_id                   :bigint           not null
#  locked_by_id                 :bigint
#  pay_rate_plan_id             :bigint
#
# Indexes
#
#  index_pay_schemes_on_company_id_and_name  (company_id,name) UNIQUE WHERE (discarded_at IS NULL)
#  index_pay_schemes_on_locked_by_id         (locked_by_id)
#  index_pay_schemes_on_pay_rate_plan_id     (pay_rate_plan_id)
#  index_pay_schemes_one_default             (company_id) UNIQUE WHERE (is_default AND (discarded_at IS NULL))
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (locked_by_id => users.id)
#  fk_rails_...  (pay_rate_plan_id => pay_rate_plans.id)
#
class PayScheme < ApplicationRecord
  include TenantScoped
  include Discard::Model
  include MinuteTime
  include PayLockable

  SCHEDULES = %w[mon-fri mon-sat mon-fri-sun 6-days all-days].freeze
  TYPE_LABELS = { "basic_plus_trips" => "Basic + Trips", "monthly_with_minimum" => "Monthly Pay with Minimum", "shift_based" => "Shift Based" }.freeze

  belongs_to :rate_plan, class_name: "PayRatePlan", foreign_key: :pay_rate_plan_id, optional: true, inverse_of: false
  has_many :route_bands, -> { order(:position, :id) }, class_name: "PaySchemeRouteBand", dependent: :delete_all, inverse_of: :scheme
  has_many :volume_tiers, -> { order(:position, :id) }, class_name: "PaySchemeVolumeTier", dependent: :delete_all, inverse_of: :scheme
  has_many :target_tiers, -> { order(:position, :id) }, class_name: "PaySchemeTargetTier", dependent: :delete_all, inverse_of: :scheme

  enum :scheme_type, TYPE_LABELS.keys.index_by(&:itself), validate: true
  enum :post_guarantee_boost_type, { percentage: "percentage", flat: "flat", fixed_rate: "fixed_rate" }, prefix: :boost, validate: true
  enum :monthly_minimum_type, { daily: "daily", monthly: "monthly" }, prefix: :minimum, validate: true
  enum :shift_overtime_pay_type, { trip_rates: "trip_rates", hourly_rate: "hourly_rate" }, prefix: :overtime_by, validate: true

  minute_time :shift_start_time, :shift_end_time

  normalizes :name, :description, with: ->(v) { v.to_s.squish.presence }
  normalizes :shift_working_days, with: ->(v) { PayRatePeriod::DAYS.first(7) & Array(v).map(&:to_s) }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id, case_sensitive: false, conditions: -> { kept }, message: "is already used by another pay scheme" }
  validates :rate_plan, presence: { message: "must be picked" }
  validates :basic_covered_schedule, :monthly_schedule, inclusion: { in: SCHEDULES }
  validates :basic_salary, :guaranteed_amount, :post_guarantee_boost_value, :rejection_fallback_basic, :monthly_pay_amount,
            :shift_salary, :shift_overtime_hourly_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :basic_covered_daily_trips, :rejection_allowed_jobs, :monthly_daily_trips, :monthly_trips,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def self.ransackable_attributes(_auth = nil) = %w[name scheme_type]

  def type_label = TYPE_LABELS[scheme_type]
  def weekly_tiers = target_tiers.select { |t| t.period == "weekly" }
  def monthly_tiers = target_tiers.select { |t| t.period == "monthly" }
end
