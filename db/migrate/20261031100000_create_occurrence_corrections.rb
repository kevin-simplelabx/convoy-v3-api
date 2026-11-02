# Trip History > Correct Record: what a run really did when the record is wrong (outcome, vehicle, driver, stop
# times and boardings). The run and what was recorded stay as they are; the corrected values sit beside them, one row
# per run, with each stop by its place in travel order. Every save is logged with who, when, why and what changed.
class CreateOccurrenceCorrections < ActiveRecord::Migration[8.1]
  def change
    create_table :occurrence_corrections do |t|
      t.references :company, null: false, foreign_key: true
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.string :outcome
      t.references :vehicle, foreign_key: true
      t.string :vehicle_plate
      t.references :driver, foreign_key: true
      t.string :driver_name
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :occurrence_corrections, %i[occurrence_id occurrence_date], unique: true
    add_check_constraint :occurrence_corrections, "outcome IN ('completed', 'incomplete')", name: "occurrence_corrections_outcome"

    create_table :occurrence_correction_stops do |t|
      t.references :company, null: false, foreign_key: true
      t.references :occurrence_correction, null: false, foreign_key: true, index: false
      t.integer :position, null: false
      t.string :stop_name
      t.integer :arrived_at
      t.integer :departed_at
      t.integer :boarded
      t.integer :alighted
      t.timestamps
    end
    add_index :occurrence_correction_stops, %i[occurrence_correction_id position], unique: true

    create_table :occurrence_correction_logs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :occurrence_correction, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.text :reason, null: false
      t.text :items, array: true, null: false, default: []
      t.datetime :created_at, null: false
    end
  end
end
