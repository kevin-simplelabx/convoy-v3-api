class AddAssignmentToTripOccurrences < ActiveRecord::Migration[8.1]
  # The assignment a run follows (nil = the trip's own plan). Added to the partitioned parent; partitions follow.
  def up
    safety_assured do
      execute "ALTER TABLE trip_occurrences ADD COLUMN trip_assignment_id bigint REFERENCES trip_assignments(id) ON DELETE SET NULL"
    end
  end

  def down
    safety_assured { execute "ALTER TABLE trip_occurrences DROP COLUMN trip_assignment_id" }
  end
end
