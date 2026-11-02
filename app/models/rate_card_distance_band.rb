# == Schema Information
#
# Table name: rate_card_distance_bands
# Database name: primary
#
#  id           :bigint           not null, primary key
#  per_km       :boolean          default(FALSE), not null
#  position     :integer          not null
#  up_to_km     :decimal(8, 1)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  company_id   :bigint           not null
#  rate_card_id :bigint           not null
#
# Indexes
#
#  index_rate_card_distance_bands_on_company_id    (company_id)
#  index_rate_card_distance_bands_on_rate_card_id  (rate_card_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (rate_card_id => rate_cards.id)
#
# A Distance Pricing band: up to N km (empty = the last band and above; per_km charges each km beyond the band before).
class RateCardDistanceBand < ApplicationRecord
  include TenantScoped

  belongs_to :rate_card, inverse_of: :distance_bands
end
