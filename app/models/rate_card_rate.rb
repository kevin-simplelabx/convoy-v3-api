# == Schema Information
#
# Table name: rate_card_rates
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  hourly_rate         :decimal(10, 2)   default(0.0), not null
#  trip_rate           :decimal(10, 2)   default(0.0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  rate_card_period_id :bigint           not null
#  vehicle_type_id     :bigint           not null
#
# Indexes
#
#  idx_on_rate_card_period_id_vehicle_type_id_62c4167068  (rate_card_period_id,vehicle_type_id) UNIQUE
#  index_rate_card_rates_on_company_id                    (company_id)
#  index_rate_card_rates_on_rate_card_period_id           (rate_card_period_id)
#  index_rate_card_rates_on_vehicle_type_id               (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_period_id => rate_card_periods.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
# Trip and hourly rate of one vehicle type in a period.
class RateCardRate < ApplicationRecord
  include TenantScoped
  audited associated_with: :period

  belongs_to :period, class_name: "RateCardPeriod", foreign_key: :rate_card_period_id, inverse_of: :rates
  belongs_to :vehicle_type

  validates :trip_rate, :hourly_rate, numericality: { greater_than_or_equal_to: 0 }
end
