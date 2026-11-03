# One attendance table for every run with names (School Bus and School Run), written by the Driver app and the Scheduler
# drawer alike: a row per child per run with their state (not_boarding, boarded, not_boarded, alighted), how and where
# they boarded and alighted, and who marked it. Replaces school_rider_boardings (School Bus, per run) and
# student_attendances (School Run, per run identity), copied over; "absent" becomes not_boarded.
class CreateOccurrencePassengers < ActiveRecord::Migration[8.1]
  def up
    create_table :occurrence_passengers do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.string :passenger_key, null: false
      t.string :name
      t.string :state, null: false
      t.datetime :boarded_at
      t.string :board_method
      t.float :board_lat
      t.float :board_lng
      t.datetime :alighted_at
      t.string :alight_method
      t.float :alight_lat
      t.float :alight_lng
      t.string :marked_by
      t.string :source, null: false, default: "driver_app"
      t.timestamps
    end
    add_index :occurrence_passengers, %i[occurrence_id occurrence_date passenger_key], unique: true,
                                                                                       name: "index_occurrence_passengers_on_run_and_key"

    # safety_assured: one-off copy of two small tables (today's attendance) into the new one, then the old ones go.
    safety_assured do
      execute <<~SQL
        INSERT INTO occurrence_passengers (company_id, occurrence_id, occurrence_date, passenger_key, state, boarded_at, board_method,
          board_lat, board_lng, alighted_at, alight_method, alight_lat, alight_lng, marked_by, source, created_at, updated_at)
        SELECT company_id, occurrence_id, occurrence_date, rid, state, boarded_at, board_method, board_lat, board_lng, alighted_at,
          alight_method, alight_lat, alight_lng, marked_by, 'driver_app', created_at, updated_at
        FROM school_rider_boardings
      SQL
      execute <<~SQL
        INSERT INTO occurrence_passengers (company_id, occurrence_id, occurrence_date, passenger_key, name, state, boarded_at,
          board_method, alighted_at, alight_method, marked_by, source, created_at, updated_at)
        SELECT a.company_id, o.id, o.date, a.student_key, a.student_name,
          CASE WHEN a.absent THEN 'not_boarded' WHEN a.alighted_at IS NOT NULL THEN 'alighted' ELSE 'boarded' END,
          a.boarded_at, CASE WHEN a.boarded_at IS NOT NULL THEN 'tick' END, a.alighted_at, CASE WHEN a.alighted_at IS NOT NULL THEN 'tick' END,
          u.name, 'office', a.created_at, a.updated_at
        FROM student_attendances a
        JOIN trip_occurrences o ON o.trip_id = a.trip_id AND o.date = a.run_date AND o.slot_no = a.slot_no AND o.part = 1
          AND o.trip_run_id IS NOT DISTINCT FROM a.trip_run_id
        LEFT JOIN users u ON u.id = a.recorded_by_id
        WHERE a.absent OR a.boarded_at IS NOT NULL
        ON CONFLICT DO NOTHING
      SQL
      drop_table :school_rider_boardings
      drop_table :student_attendances
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
