class CreateShuttles < ActiveRecord::Migration[8.1]
  def change
    # Corporate Shuttle settings on the trip.
    add_column :trips, :shuttle_return, :boolean, null: false, default: false            # has a return direction (Direction 2)
    add_column :trips, :shuttle_separate_return, :boolean, null: false, default: false   # Direction 2 uses its own stops (trip_stops direction 2)
    add_column :trips, :price_by, :string, null: false, default: "all"                   # price table rows: all | direction | run
    add_column :trips, :trip_value_per, :string, null: false, default: "run"             # run | day (whole day split over the runs)
    add_column :trips, :trip_value_return, :decimal, precision: 10, scale: 2             # trip value of Direction 2 runs
    add_column :trips, :route_tags, :string, array: true, null: false, default: []
    add_column :trips, :color, :string
    add_column :trips, :approved_riders_only, :boolean, null: false, default: false
    add_column :trips, :seat_reservation, :boolean, null: false, default: false
    add_column :trips, :head_count, :boolean, null: false, default: false

    # Name of a stop on the way back when the return uses the same stops reversed.
    add_column :trip_stops, :return_name, :string

    # One timed run of a shuttle in a direction (position 0 = first timing). Start and end come from its stop times.
    create_table :trip_runs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :direction, null: false, default: 1
      t.integer :position, null: false
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.decimal :trip_value, precision: 10, scale: 2          # own driver trip value for this run (else the trip's)
      t.boolean :standby_needed, null: false, default: true   # Standby Area: Needed For These Runs
      t.timestamps
    end
    add_unique_constraint :trip_runs, %i[trip_id direction position], deferrable: :deferred, name: "trip_runs_order"

    # The time at each stop of a run (empty = the bus does not stop there on this run).
    create_table :trip_run_times do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip_run, null: false, foreign_key: true
      t.references :trip_stop, null: false, foreign_key: true
      t.integer :time
      t.timestamps
    end
    add_index :trip_run_times, %i[trip_run_id trip_stop_id], unique: true

    # Runs That Move Together: run slots in one group move together when dragged.
    create_table :trip_run_groups do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.timestamps
    end

    # Vehicle for Each Run: the bus of vehicle slot n on a run (unassigned = sent to Unassigned Trips on purpose).
    create_table :trip_run_slots do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip_run, null: false, foreign_key: true
      t.integer :slot_no, null: false
      t.references :vehicle, foreign_key: true
      t.boolean :unassigned, null: false, default: false
      t.references :trip_run_group, foreign_key: true
      t.timestamps
    end
    add_index :trip_run_slots, %i[trip_run_id slot_no], unique: true

    # Shuttle price table: a cell per row (all runs, a direction or one run) and column (whole route or one vehicle slot).
    create_table :trip_price_cells do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :direction                                     # row: null = all runs, 1 or 2 = that direction
      t.references :trip_run, foreign_key: true                # row: one run (price by run)
      t.integer :slot_no                                       # column: null = whole route
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :trip_price_cells, "trip_id, COALESCE(direction, 0), COALESCE(trip_run_id, 0), COALESCE(slot_no, 0)",
              unique: true, name: "index_trip_price_cells_one_per_cell"
  end
end
