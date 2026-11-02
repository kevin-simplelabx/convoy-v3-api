class AddReplacementToTripOccurrences < ActiveRecord::Migration[8.1]
  # The replacement a run follows, and a driver who is not on file (replacement typed by name, external buses).
  def up
    safety_assured do
      execute <<~SQL
        ALTER TABLE trip_occurrences
          ADD COLUMN replacement_id bigint REFERENCES replacements(id) ON DELETE SET NULL,
          ADD COLUMN driver_name varchar,
          ADD COLUMN driver_phone varchar
      SQL
    end
  end

  def down
    safety_assured { execute "ALTER TABLE trip_occurrences DROP COLUMN replacement_id, DROP COLUMN driver_name, DROP COLUMN driver_phone" }
  end
end
