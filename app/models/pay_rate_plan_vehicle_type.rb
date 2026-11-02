# A vehicle type a rate plan has rates for.
# == Schema Information
#
# Table name: pay_rate_plan_vehicle_types
# Database name: primary
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  pay_rate_plan_id :bigint           not null
#  vehicle_type_id  :bigint           not null
#
# Indexes
#
#  index_pay_rate_plan_vehicle_types_on_vehicle_type_id  (vehicle_type_id)
#  index_pay_rate_plan_vehicle_types_unique              (pay_rate_plan_id,vehicle_type_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (pay_rate_plan_id => pay_rate_plans.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class PayRatePlanVehicleType < ApplicationRecord
  belongs_to :pay_rate_plan
  belongs_to :vehicle_type
end
