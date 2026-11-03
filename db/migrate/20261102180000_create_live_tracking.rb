# Live Map: the devices that report where a bus is (the Convoy Driver app on the driver's phone or a GPS tracker fitted
# to the bus) and the last report of each bus — one row per vehicle, overwritten on every ping (the history of a run's
# pings stays in occurrence_positions).
class CreateLiveTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :tracking_devices do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.string :kind, null: false
      t.string :name, null: false
      t.string :identifier
      t.integer :report_interval_seconds, null: false, default: 10
      t.boolean :sharing_enabled, null: false, default: true
      t.timestamps
    end
    add_index :tracking_devices, %i[company_id identifier], unique: true, where: "identifier IS NOT NULL"

    create_table :vehicle_live_positions do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true, index: { unique: true }
      t.references :tracking_device, foreign_key: { on_delete: :nullify }
      t.timestamptz :recorded_at, null: false
      t.float :lat, null: false
      t.float :lng, null: false
      t.float :speed_kmh, limit: 24
      t.integer :heading, limit: 2
      t.integer :battery_pct, limit: 2
      t.string :gps_signal
      t.integer :gsm_bars, limit: 2
      t.bigint :occurrence_id
      t.date :occurrence_date
    end
  end
end
