class CreateTrackingLinks < ActiveRecord::Migration[8.1]
  def change
    # Share Tracking Link: a public page for one run. The snapshot (stops with pins, bus, driver's first name) is
    # what the page shows, frozen when shared (JSON on purpose: display data, not queried). One link per run, refreshed
    # on every share; closes 24 hours after the run ends.
    create_table :tracking_links do |t|
      t.references :company, null: false, foreign_key: true
      t.string :token, null: false
      t.references :trip, null: false, foreign_key: true
      t.date :run_date, null: false
      t.references :trip_run, foreign_key: true
      t.integer :slot_no, null: false, default: 1
      t.jsonb   :snapshot, null: false, default: {}
      t.datetime :expires_at, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :tracking_links, :token, unique: true
    add_index :tracking_links, %i[trip_id run_date trip_run_id slot_no], unique: true, name: "index_tracking_links_one_per_run"
  end
end
