# Bus Fares › drawn zones and surcharge areas as rows (was a free-form jsonb `area` on fare_tiers / fare_surcharges):
# one row per outline (`exclude` = a cut-out), the ring a 2-D float array [[lat, lng], …]. Owned by a tier or a
# surcharge (exactly one).
class CreateFareAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :fare_areas do |t|
      t.references :fare_tier, foreign_key: { on_delete: :cascade }
      t.references :fare_surcharge, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.boolean :exclude, null: false, default: false
      t.float :ring, array: true, null: false
      t.check_constraint "num_nonnulls(fare_tier_id, fare_surcharge_id) = 1", name: "fare_areas_one_owner"
    end
  end
end
