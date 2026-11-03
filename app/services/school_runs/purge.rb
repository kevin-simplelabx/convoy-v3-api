# Student data of a School Run is kept 7 years after its last run, then cleared: students, earlier lists and attendance.
# Runs daily. Trips that never end keep theirs.
module SchoolRuns
  class Purge < ApplicationService
    KEEP_DAYS = (7 * 365) + 2

    def call(today = Date.current)
      Trip.with_discarded.school_run.where.not(end_mode: "never").where(students_purged_at: nil).find_each.select do |t|
        t.last_date && t.last_date + KEEP_DAYS < today
      end.each { |t| purge(t) }
    end

    private

    def purge(trip)
      Trip.transaction do
        TripStopStudent.where(trip_stop_id: trip.stops.select(:id)).delete_all
        trip.route_list_versions.destroy_all
        OccurrencePassenger.where(occurrence_id: trip.occurrences.select(:id)).delete_all
        trip.update_columns(pax: 0, students_purged_at: Time.current)
      end
    end
  end
end
