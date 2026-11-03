class AddDriverViewToTripOccurrences < ActiveRecord::Migration[8.1]
  # Convoy Driver app: the driver a replacement took the run from (they still see it, as Replaced), and when the driver
  # last opened the run (the New badge; Sync clears it when the run's driver, bus or time changes).
  # safety_assured: the partitioned parent can't take NOT VALID foreign keys or concurrent indexes; the new columns are all
  # NULL and the partial indexes are empty, so this is a quick scan of today + 120 days of runs. Run occurrences:sync after.
  def up
    safety_assured do
      execute <<~SQL
        ALTER TABLE trip_occurrences
          ADD COLUMN original_driver_id bigint REFERENCES drivers(id) ON DELETE SET NULL,
          ADD COLUMN original_operator_driver_id bigint REFERENCES operator_drivers(id) ON DELETE SET NULL,
          ADD COLUMN driver_seen_at timestamp(6) without time zone;
        CREATE INDEX index_trip_occurrences_on_original_driver_date ON trip_occurrences (original_driver_id, date)
          WHERE original_driver_id IS NOT NULL;
        CREATE INDEX index_trip_occurrences_on_original_operator_driver_date ON trip_occurrences (original_operator_driver_id, date)
          WHERE original_operator_driver_id IS NOT NULL;
      SQL
    end
  end

  def down
    safety_assured do
      execute "ALTER TABLE trip_occurrences DROP COLUMN original_driver_id, DROP COLUMN original_operator_driver_id, DROP COLUMN driver_seen_at"
    end
  end
end
