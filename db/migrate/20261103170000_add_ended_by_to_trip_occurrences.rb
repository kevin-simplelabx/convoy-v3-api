class AddEndedByToTripOccurrences < ActiveRecord::Migration[8.1]
  # Force End Trip: who ended the run from the drawer (a driver's End in the app leaves it empty).
  # safety_assured: a partitioned table can't take a NOT VALID foreign key; the new column is all NULL, so the check is a
  # quick scan of today + 120 days of runs.
  def up
    safety_assured do
      execute "ALTER TABLE trip_occurrences ADD COLUMN ended_by_id bigint REFERENCES users(id) ON DELETE SET NULL"
    end
  end

  def down
    safety_assured { execute "ALTER TABLE trip_occurrences DROP COLUMN ended_by_id" }
  end
end
