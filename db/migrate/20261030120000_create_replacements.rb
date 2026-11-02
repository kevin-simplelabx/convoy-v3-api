class CreateReplacements < ActiveRecord::Migration[8.1]
  def change
    # Replacements (layer 4): Driver Unavailable (drv), Vehicle Down (veh), Crew Swap (crew), Handover During the Trip (hand).
    # For one run (trip, run_date, trip_run, slot_no) or, for drv and veh, every run on original_vehicle in a date range
    # (Driver Away / Vehicle Down on the vehicle panel).
    create_table :replacements do |t|
      t.references :company, null: false, foreign_key: true
      t.string  :kind, null: false                              # drv | veh | crew | hand
      t.string  :scope, null: false, default: "run"             # run | range
      t.references :trip, foreign_key: true                     # scope run
      t.date :run_date                                       # scope run
      t.references :trip_run, foreign_key: true                 # scope run, shuttles
      t.integer :slot_no                                        # scope run
      t.references :original_vehicle, null: false, foreign_key: { to_table: :vehicles }
      t.date    :starts_on, null: false
      t.date    :ends_on, null: false
      t.references :vehicle, foreign_key: true                  # new bus (veh, crew, hand)
      t.references :driver, foreign_key: true                   # new driver, an own driver
      t.references :operator_driver, foreign_key: true          # new driver, an operator driver
      t.string  :driver_name                                    # new driver not on file
      t.string  :driver_phone
      t.string  :handover_stop
      t.integer :handover_time                                  # minutes after midnight of the run date
      t.string  :eta
      t.string  :pay_split                                      # hand: original | new | both | split
      t.integer :original_share                                 # hand split: % of the trip value for the original crew
      t.string  :arranged_by, null: false, default: "operator"  # operator (they arrange and pay) | us (we pay the new bus)
      t.decimal :deduction, precision: 12, scale: 2             # us: taken from the original operator's pay
      t.decimal :premium, precision: 12, scale: 2               # us: extra charged to the original operator
      t.text    :reason
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :replacements, %i[company_id starts_on ends_on]
    add_index :replacements, %i[trip_id run_date]
    add_check_constraint :replacements, "kind IN ('drv','veh','crew','hand')", name: "replacements_kind"
    add_check_constraint :replacements, "scope = 'run' OR kind IN ('drv','veh')", name: "replacements_range_kinds"
    add_check_constraint :replacements, "ends_on >= starts_on", name: "replacements_dates"

    # Who was told about a replacement and how (recorded only until the Convoy App and messaging are wired).
    create_table :replacement_notifications do |t|
      t.references :company, null: false, foreign_key: true
      t.references :replacement, null: false, foreign_key: true
      t.string  :audiences, array: true, null: false, default: []   # guests | parents
      t.string  :channels, array: true, null: false, default: []    # email | push
      t.text    :message, null: false
      t.references :sent_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
