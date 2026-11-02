class AddSchoolRoutesToOccurrences < ActiveRecord::Migration[8.1]
  # A run is of a trip or of a School Bus route (exactly one). Replacements can name a route run too.
  # safety_assured: run before the table holds production data; the identity index is rebuilt to include the route.
  def up
    safety_assured do
      execute <<~SQL
        ALTER TABLE trip_occurrences
          ALTER COLUMN trip_id DROP NOT NULL,
          ALTER COLUMN client_id DROP NOT NULL,
          ADD COLUMN school_route_id bigint REFERENCES school_routes(id),
          ADD CONSTRAINT trip_occurrences_one_source CHECK (num_nonnulls(trip_id, school_route_id) = 1);
        DROP INDEX index_trip_occurrences_identity;
        CREATE UNIQUE INDEX index_trip_occurrences_identity
          ON trip_occurrences (COALESCE(trip_id, 0), COALESCE(school_route_id, 0), date, COALESCE(trip_run_id, 0), slot_no, part);
        CREATE INDEX index_trip_occurrences_on_route_date ON trip_occurrences (school_route_id, date) WHERE school_route_id IS NOT NULL;
      SQL
    end
    add_reference :replacements, :school_route, index: false
    add_foreign_key :replacements, :school_routes, validate: false
    add_reference :notices, :school, index: false
    add_foreign_key :notices, :schools, validate: false
    remove_check_constraint :replacements, name: "replacements_range_kinds"
    add_check_constraint :replacements, "scope = 'range' OR num_nonnulls(trip_id, school_route_id) = 1", name: "replacements_run_source", validate: false
    add_check_constraint :replacements, "scope = 'run' OR kind IN ('drv','veh')", name: "replacements_range_kinds", validate: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
