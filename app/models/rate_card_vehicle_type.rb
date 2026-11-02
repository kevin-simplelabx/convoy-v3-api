# A vehicle type a rate card prices: one column of the card, in order.
# == Schema Information
#
# Table name: rate_card_vehicle_types
# Database name: primary
#
#  id              :bigint           not null, primary key
#  position        :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  rate_card_id    :bigint           not null
#  vehicle_type_id :bigint           not null
#
# Indexes
#
#  idx_on_rate_card_id_vehicle_type_id_a715fca998    (rate_card_id,vehicle_type_id) UNIQUE
#  index_rate_card_vehicle_types_on_company_id       (company_id)
#  index_rate_card_vehicle_types_on_rate_card_id     (rate_card_id)
#  index_rate_card_vehicle_types_on_vehicle_type_id  (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_id => rate_cards.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
class RateCardVehicleType < ApplicationRecord
  include TenantScoped

  belongs_to :rate_card, inverse_of: :card_vehicle_types
  belongs_to :vehicle_type
end
