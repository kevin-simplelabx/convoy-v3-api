# One target of an Extra Charge: a fare tier / zone of the year's table, or a bus size (per-bus fares).
# == Schema Information
#
# Table name: fare_adjustment_targets
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  bus_type           :string
#  fare_adjustment_id :bigint           not null
#  fare_tier_id       :bigint
#
# Indexes
#
#  idx_on_fare_adjustment_id_bus_type_d4427973e8      (fare_adjustment_id,bus_type) UNIQUE WHERE (bus_type IS NOT NULL)
#  idx_on_fare_adjustment_id_fare_tier_id_99d63c766c  (fare_adjustment_id,fare_tier_id) UNIQUE WHERE (fare_tier_id IS NOT NULL)
#  index_fare_adjustment_targets_on_fare_tier_id      (fare_tier_id)
#
# Foreign Keys
#
#  fk_rails_...  (fare_adjustment_id => fare_adjustments.id) ON DELETE => cascade
#  fk_rails_...  (fare_tier_id => fare_tiers.id) ON DELETE => cascade
#
class FareAdjustmentTarget < ApplicationRecord
  belongs_to :fare_adjustment, inverse_of: :targets
  belongs_to :fare_tier, optional: true

  validate { errors.add(:base, "Pick a tier or a bus size") unless fare_tier_id.present? ^ bus_type.present? }
  validates :bus_type, inclusion: { in: SchoolBus::BUS_TYPES.keys }, allow_nil: true

  # The key the fare maths uses: a tier id, or "bus:<type>".
  def key = fare_tier_id || "bus:#{bus_type}"
end
