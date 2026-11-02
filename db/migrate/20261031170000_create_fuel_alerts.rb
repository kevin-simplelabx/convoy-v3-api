# Fuel & Energy > Needs a Look: unusual fills of the last 90 days found by FuelAlerts::Scan (efficiency far off the bus's
# usual, odometer lower than before, two fills close together, an oversized fill, a high price, rising use per km).
# key identifies one finding (kind + entry, or the trend of a bus, energy and month) so Mark Checked survives a rescan.
# Also energy_km on fuel_entries: km since the bus's previous reading of the same energy (fuel, elec, def), used for
# fuel per km by driver, vehicle or company.
class CreateFuelAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :fuel_alerts do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :vehicle, null: false, foreign_key: true
      t.references :fuel_entry, foreign_key: { on_delete: :cascade }
      t.string :key, null: false
      t.string :kind, null: false
      t.string :tone, null: false, default: "warn"
      t.string :metric
      t.text :message, null: false
      t.date :date, null: false
      t.string :status, null: false, default: "open"
      t.references :checked_by, foreign_key: { to_table: :users }
      t.datetime :checked_at
      t.timestamps
    end
    add_index :fuel_alerts, %i[company_id key], unique: true
    add_index :fuel_alerts, %i[company_id status date]
    add_check_constraint :fuel_alerts, "kind IN ('eff', 'odo', 'dbl', 'big', 'price', 'trend')", name: "fuel_alerts_kind"
    add_check_constraint :fuel_alerts, "status IN ('open', 'checked')", name: "fuel_alerts_status"

    add_column :fuel_entries, :energy_km, :integer
  end
end
