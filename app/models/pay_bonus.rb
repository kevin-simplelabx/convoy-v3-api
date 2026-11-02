# HR > Bonuses: a campaign on top of pay schemes (Pay::Bonuses works out what a driver earns from it).
# == Schema Information
#
# Table name: pay_bonuses
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  all_schemes         :boolean          default(TRUE), not null
#  description         :string
#  discarded_at        :datetime
#  frequency           :string           default("monthly"), not null
#  last_period_on      :date
#  locked_at           :datetime
#  name                :string           not null
#  overlap_daily       :string           default("additive"), not null
#  overlap_monthly     :string           default("additive"), not null
#  overlap_weekly      :string           default("additive"), not null
#  payout_delay_months :integer          default(1), not null
#  payout_type         :string           default("end_of_period"), not null
#  plan_type           :string           default("trip_target"), not null
#  requires_sign_up    :boolean          default(FALSE), not null
#  sign_up_from        :date
#  sign_up_to          :date
#  starts_on           :date             not null
#  terms               :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  locked_by_id        :bigint
#
# Indexes
#
#  index_pay_bonuses_on_company_id_and_starts_on  (company_id,starts_on)
#  index_pay_bonuses_on_locked_by_id              (locked_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (locked_by_id => users.id)
#
class PayBonus < ApplicationRecord
  include TenantScoped
  include Discard::Model
  include PayLockable

  TYPE_LABELS = { "trip_target" => "Trip Target", "reliability_otp" => "On-Time Performance", "reliability_attendance" => "Attendance" }.freeze
  FREQUENCIES = %w[daily weekly monthly quarterly half_yearly yearly].freeze
  MONTHS = { "monthly" => 1, "quarterly" => 3, "half_yearly" => 6, "yearly" => 12 }.freeze
  OVERLAPS = %w[additive supercede prevail].freeze

  has_many :tiers, -> { order(:position, :id) }, class_name: "PayBonusTier", dependent: :delete_all, inverse_of: :bonus
  has_many :payments, -> { order(:position, :id) }, class_name: "PayBonusPayment", dependent: :delete_all, inverse_of: :bonus
  has_many :bonus_schemes, class_name: "PayBonusScheme", dependent: :delete_all
  has_many :schemes, through: :bonus_schemes, source: :pay_scheme
  has_many :bonus_drivers, class_name: "PayBonusDriver", dependent: :delete_all
  has_many :excluded_periods, -> { order(:starts_on) }, class_name: "PayBonusExcludedPeriod", dependent: :delete_all, inverse_of: :bonus

  enum :plan_type, TYPE_LABELS.keys.index_by(&:itself), validate: true
  enum :frequency, FREQUENCIES.index_by(&:itself), prefix: :every, validate: true
  enum :payout_type, { end_of_period: "end_of_period", next_payroll_cycle: "next_payroll_cycle", x_months_later: "x_months_later",
                       split_trenches: "split_trenches" }, prefix: :paid, validate: true

  normalizes :name, :description, with: ->(v) { v.to_s.squish.presence }

  validates :name, :starts_on, presence: true
  validates :overlap_daily, :overlap_weekly, :overlap_monthly, inclusion: { in: OVERLAPS }
  validates :payout_delay_months, numericality: { only_integer: true, greater_than: 0 }

  def type_label = TYPE_LABELS[plan_type]
  def trip_target? = plan_type == "trip_target"

  # Last day of the bonus (nil = no end).
  def ends_on
    return nil unless last_period_on
    return last_period_on if every_daily?
    return last_period_on + 6 if every_weekly?

    (last_period_on >> (MONTHS.fetch(frequency) - 1)).end_of_month
  end

  # upcoming | running | ended
  def status(today = Date.current)
    return "upcoming" if starts_on > today

    ends_on && ends_on < today ? "ended" : "running"
  end

  def covers?(from, to) = starts_on <= to && (ends_on.nil? || ends_on >= from)

  def eligible_driver_ids = bonus_drivers.select { |d| d.role == "eligible" }.map(&:driver_id)
  def signed_up_driver_ids = bonus_drivers.select { |d| d.role == "signed_up" }.map(&:driver_id)

  # The tier reached by a number of trips (highest target) or a percentage (highest From within its range).
  def tier_for(value)
    if trip_target? then tiers.select { |t| t.target_trips && value >= t.target_trips }.max_by(&:target_trips)
    else tiers.select { |t| t.metric_min && value >= t.metric_min && value <= (t.metric_max || 100) }.max_by(&:metric_min)
    end
  end
end
