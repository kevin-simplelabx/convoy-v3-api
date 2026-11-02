class CreateTripAssignments < ActiveRecord::Migration[8.1]
  def change
    # From a date on, who runs some vehicle slots of a trip (Assign page, or a drop From This Date On):
    # an own bus, an operator (with or without the bus named yet), or nobody. The latest effective_from <= date wins.
    create_table :trip_assignments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.date    :effective_from, null: false
      t.string  :assignee, null: false                  # own | operator | none
      t.references :operator, foreign_key: true          # operator (managed or external) when assignee = operator
      t.references :vehicle, foreign_key: true           # the bus (empty: operator named, bus not known yet)
      t.decimal :pay_amount, precision: 12, scale: 2     # agreed operator pay
      t.string  :pay_basis, null: false, default: "run"  # run | day | month
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :trip_assignments, %i[trip_id effective_from]

    # The run slots an assignment covers (trip_run empty for trips that are not shuttles).
    create_table :trip_assignment_slots do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip_assignment, null: false, foreign_key: true
      t.references :trip_run, foreign_key: true
      t.integer :slot_no, null: false
      t.timestamps
    end
    add_index :trip_assignment_slots, %i[trip_assignment_id trip_run_id slot_no], unique: true, name: "index_trip_assignment_slots_once"

    # No Fixed Bus: the bus changes from day to day; riders are not alerted about bus changes.
    add_column :trips, :no_fixed_bus, :boolean, null: false, default: false
  end
end
