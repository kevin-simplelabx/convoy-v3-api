# An Extra Charge on a school's locked fares (Bus Fares › Extra Charges): +% or +amount on every bill from from_month
# (to to_month, or on into later academic years), or a one-off amount on the from_month bill; for every rider or only
# the picked targets. Scheduled until its first month, then Active, then Ended; only Scheduled ones can change.
# == Schema Information
#
# Table name: fare_adjustments
# Database name: primary
#
#  id               :bigint           not null, primary key
#  from_month       :date             not null
#  kind             :string           not null
#  name             :string           not null
#  note             :string
#  to_month         :date
#  value            :decimal(12, 2)   not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :bigint           not null
#  company_id       :bigint           not null
#  created_by_id    :bigint
#  school_id        :bigint           not null
#
# Indexes
#
#  index_fare_adjustments_on_academic_year_id          (academic_year_id)
#  index_fare_adjustments_on_school_id_and_from_month  (school_id,from_month)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id) ON DELETE => cascade
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (school_id => schools.id)
#
class FareAdjustment < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  self.ignored_columns += [ "targets" ] # moved to fare_adjustment_targets (20261105100200); dropped later

  KINDS = %w[pct amt once].freeze

  belongs_to :school
  belongs_to :academic_year
  belongs_to :created_by, class_name: "User", optional: true
  has_many :targets, class_name: "FareAdjustmentTarget", dependent: :delete_all, inverse_of: :fare_adjustment

  validates :name, presence: true
  validates :kind, inclusion: { in: KINDS }
  validates :value, numericality: { greater_than: 0 }
  validates :value, numericality: { less_than_or_equal_to: 100, message: "must be 100 or less" }, if: -> { kind == "pct" }
  validate :months_in_order

  before_validation do
    self.from_month = from_month&.beginning_of_month
    self.to_month = kind == "once" ? nil : to_month&.beginning_of_month
  end

  def state(month = Date.current.beginning_of_month)
    last = kind == "once" ? from_month : to_month
    return "scheduled" if from_month > month
    return "ended" if last && last < month

    "active"
  end

  def tier_ids = targets.filter_map(&:fare_tier_id)
  def bus_types = targets.filter_map(&:bus_type)

  # Does it apply to a bill of a month for a target (a tier id or "bus:<type>")? No targets = every rider.
  def applies?(month, target)
    keys = targets.map(&:key)
    key = target.to_s.start_with?("bus:") ? target.to_s : target.to_i
    (keys.empty? || keys.include?(key)) &&
      (kind == "once" ? from_month == month : from_month <= month && (to_month.nil? || month <= to_month))
  end

  private

  def months_in_order
    errors.add(:to_month, "must be on or after the start month") if to_month && from_month && to_month < from_month
  end
end
