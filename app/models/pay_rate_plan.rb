# HR > Rate Plans: per-trip and per-hour rates for each vehicle type by day and time (periods). Used by pay schemes.
# == Schema Information
#
# Table name: pay_rate_plans
# Database name: primary
#
#  id           :bigint           not null, primary key
#  description  :string
#  discarded_at :datetime
#  locked_at    :datetime
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#  locked_by_id :bigint
#
# Indexes
#
#  index_pay_rate_plans_on_company_id_and_name  (company_id,name) UNIQUE WHERE (discarded_at IS NULL)
#  index_pay_rate_plans_on_locked_by_id         (locked_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (locked_by_id => users.id)
#
class PayRatePlan < ApplicationRecord
  include TenantScoped
  include Discard::Model
  include PayLockable

  has_many :plan_vehicle_types, class_name: "PayRatePlanVehicleType", dependent: :delete_all
  has_many :vehicle_types, through: :plan_vehicle_types
  has_many :periods, -> { order(:position, :id) }, class_name: "PayRatePeriod", dependent: :destroy, inverse_of: :plan
  has_many :schemes, class_name: "PayScheme", dependent: :restrict_with_error

  normalizes :name, :description, with: ->(v) { v.to_s.squish.presence }

  validates :name, presence: true
  validates :name, uniqueness: { scope: :company_id, case_sensitive: false, conditions: -> { kept }, message: "is already used by another rate plan" }

  def self.ransackable_attributes(_auth = nil) = %w[name]

  # Rates of a period by vehicle type id: { vehicle_type_id => PayRate }.
  def rate_table = periods.to_h { |p| [ p.id, p.rates.index_by(&:vehicle_type_id) ] }
end
