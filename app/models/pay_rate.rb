# The rate of a period for one vehicle type: per trip (times the trip value) and per hour (disposal and hourly trips).
# Empty = S$0.
# == Schema Information
#
# Table name: pay_rates
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  per_hour           :decimal(12, 2)
#  per_trip           :decimal(12, 2)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  pay_rate_period_id :bigint           not null
#  vehicle_type_id    :bigint           not null
#
# Indexes
#
#  index_pay_rates_on_pay_rate_period_id_and_vehicle_type_id  (pay_rate_period_id,vehicle_type_id) UNIQUE
#  index_pay_rates_on_vehicle_type_id                         (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (pay_rate_period_id => pay_rate_periods.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class PayRate < ApplicationRecord
  belongs_to :period, class_name: "PayRatePeriod", foreign_key: :pay_rate_period_id, inverse_of: :rates
  belongs_to :vehicle_type

  validates :per_trip, :per_hour, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
