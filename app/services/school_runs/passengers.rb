# Passenger List of a run (trip drawer): every stop with its students, as the route list in force that day had them
# (an Earlier List for dates before an Apply From), and each student's Boarded / Alighted / Absent.
module SchoolRuns
  class Passengers < ApplicationService
    def initialize(occurrence)
      @occ = occurrence
      @trip = occurrence.trip
    end

    def call
      marks = StudentAttendance.where(trip_id: @trip.id, run_date: @occ.date, trip_run_id: @occ.trip_run_id, slot_no: @occ.slot_no)
                               .includes(:recorded_by).index_by(&:student_key)
      version = @trip.route_list_versions.where(valid_until: @occ.date..).order(:valid_until).first
      stops = version ? version.stops.includes(:students) : TripStop.where(trip_id: @trip.id, direction: 1).includes(:students).order(:position)
      {
        list: version ? version.name : (@trip.route_list_name || "Current list"),
        stops: stops.map do |s|
          { name: s.name, time: Clock.hm(s.scheduled_time), students: s.students.map { |st| student(st, marks[st.key]) } }
        end
      }
    end

    private

    def student(st, mark)
      { key: st.key, name: st.name, class_name: st.class_name, parent_name: st.parent_name, phone: st.phone, phone2: st.phone2,
        note: st.note, status: mark&.status || "not_marked", boarded_at: mark&.boarded_at, alighted_at: mark&.alighted_at,
        by: mark&.recorded_by&.name, at: mark&.updated_at }
    end
  end
end
