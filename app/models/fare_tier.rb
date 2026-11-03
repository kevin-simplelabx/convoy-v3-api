# A distance tier (up to max_km; the last is open-ended) or a zone (name, postal sectors and / or a drawn area — the
# first matching zone applies) of a fare table, with its fares: 2-way (or AM) and PM a year, own 1-way, per-period
# amounts (custom distribution), Small Bus / Express own fares, CCA price. Prices by bus size are in fare_tier_sizes.
# == Schema Information
#
# Table name: fare_tiers
# Database name: primary
#
#  id              :bigint           not null, primary key
#  area            :jsonb
#  cca_fare        :decimal(12, 2)
#  express_fare    :decimal(12, 2)
#  fare            :decimal(12, 2)
#  max_km          :decimal(6, 2)
#  name            :string
#  one_way_fare    :decimal(12, 2)
#  period_fares    :decimal(12, 2)   default([]), not null, is an Array
#  period_pm_fares :decimal(12, 2)   default([]), not null, is an Array
#  pm_fare         :decimal(12, 2)
#  position        :integer          not null
#  sectors         :string           default([]), not null, is an Array
#  small_fare      :decimal(12, 2)
#  fare_table_id   :bigint           not null
#
# Indexes
#
#  index_fare_tiers_on_fare_table_id_and_position  (fare_table_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (fare_table_id => fare_tables.id) ON DELETE => cascade
#
class FareTier < ApplicationRecord
  belongs_to :fare_table, inverse_of: :tiers
  has_many :sizes, class_name: "FareTierSize", dependent: :delete_all, inverse_of: :fare_tier

  def area? = area.present? && Array(area).any?
end
