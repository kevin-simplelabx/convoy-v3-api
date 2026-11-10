# Extra Charges › the tiers / zones or bus sizes a charge is for (was a string array `targets` of tier ids and
# "bus:<type>"): a tier (FK) or a bus type, exactly one; no rows = every rider.
class CreateFareAdjustmentTargets < ActiveRecord::Migration[8.1]
  def change
    create_table :fare_adjustment_targets do |t|
      t.references :fare_adjustment, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :fare_tier, foreign_key: { on_delete: :cascade }
      t.string :bus_type
      t.check_constraint "num_nonnulls(fare_tier_id, bus_type) = 1", name: "fare_adjustment_targets_one_target"
      t.index %i[fare_adjustment_id fare_tier_id], unique: true, where: "fare_tier_id IS NOT NULL"
      t.index %i[fare_adjustment_id bus_type], unique: true, where: "bus_type IS NOT NULL"
    end
  end
end
