# == Schema Information
#
# Table name: rate_card_amounts
# Database name: primary
#
#  id                         :bigint           not null, primary key
#  amount                     :decimal(10, 2)   default(0.0), not null
#  kind                       :string           not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  company_id                 :bigint           not null
#  rate_card_distance_band_id :bigint
#  rate_card_id               :bigint           not null
#  vehicle_type_id            :bigint           not null
#
# Indexes
#
#  index_rate_card_amounts_on_company_id                  (company_id)
#  index_rate_card_amounts_on_rate_card_distance_band_id  (rate_card_distance_band_id)
#  index_rate_card_amounts_on_rate_card_id                (rate_card_id)
#  index_rate_card_amounts_on_vehicle_type_id             (vehicle_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_distance_band_id => rate_card_distance_bands.id)
#  fk_rails_...  (rate_card_id => rate_cards.id)
#  fk_rails_...  (vehicle_type_id => vehicle_types.id)
#
# An extra amount by vehicle type: a distance band's add-on, the fee per extra stop, or the disposal charge per km.
class RateCardAmount < ApplicationRecord
  include TenantScoped

  KINDS = %w[distance_band stop_fee disposal_km].freeze

  belongs_to :rate_card, inverse_of: :amounts
  belongs_to :rate_card_distance_band, optional: true
  belongs_to :vehicle_type

  validates :kind, inclusion: { in: KINDS }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
