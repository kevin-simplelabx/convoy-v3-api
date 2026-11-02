# Runs skipped by the calendar are stored with status skipped (Trip History).
class AllowSkippedOccurrences < ActiveRecord::Migration[8.1]
  STATUSES = %w[scheduled cancelled completed removed skipped].freeze

  def up
    # safety_assured: PostgreSQL 17 can't add a NOT VALID check to a partitioned table. The new check only widens the
    # old one (every stored status passes), so the scan finds nothing; it takes a short lock per partition.
    safety_assured do
      remove_check_constraint :trip_occurrences, name: "trip_occurrences_status"
      add_check_constraint :trip_occurrences, "status IN (#{STATUSES.map { |s| "'#{s}'" }.join(', ')})", name: "trip_occurrences_status"
    end
  end

  def down
    safety_assured do
      remove_check_constraint :trip_occurrences, name: "trip_occurrences_status"
      add_check_constraint :trip_occurrences, "status IN ('scheduled', 'cancelled', 'completed', 'removed')", name: "trip_occurrences_status"
    end
  end
end
