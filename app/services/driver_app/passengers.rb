# The names on a run for the Driver app (Attendance, All Passengers, Before You Go): each child with their pick-up and
# drop-off point (positions on the run's points) and their state in the app's words:
#   expected          on the list, not ticked yet
#   bus_not_required  the parent said so (Convoy App); School Bus only
#   not_boarding      marked before the trip (Edit Route)
#   boarded, not_boarded (ticked as not there), alighted
# School Bus: the route's riders, their Bus Not Required and what was recorded on the run (occurrence_passengers); each has a
# QR boarding pass code. School Run: the route list the company uploaded and the attendance marked on the run.
# Other runs carry no names (counts only): [].
module DriverApp
  class Passengers < ApplicationService
    def initialize(occ, points:)
      @occ = occ
      @points = points
    end

    def call
      if @occ.school_route then school_bus
      elsif @occ.trip&.school_run? then school_run
      else []
      end
    end

    private

    def school_bus
      route = @occ.school_route
      plan = route.plan
      am = plan.session == "am"
      school_point = @points.find { it[:school] }[:position]
      rids = route.stops.flat_map { |s| s.riders.map(&:rid) }
      info = SchoolRider.of_school_on(plan.school, @occ.date).where(rid: rids).index_by(&:rid)
      absences = plan.school.rider_absences.where(date: @occ.date, rid: rids).index_by(&:rid)
      marks = @occ.passenger_marks.index_by(&:passenger_key)
      route.stops.each_with_index.flat_map do |stop, i|
        stop.riders.sort_by(&:rid).map do |r|
          rider = info[r.rid]
          absence = absences[r.rid]&.then { it.covers?(plan.session) ? it : nil }
          # what the driver marked wins (a child who came after all), then the parent's Bus Not Required
          state = marks[r.rid]&.state || (absence ? "bus_not_required" : "expected")
          { id: r.rid, name: rider&.name || r.rid, gender: rider&.gender, level: rider&.grade, address: rider&.address,
            parent_name: rider&.parent_name, parent_phone: rider&.parent_contact, note: rider&.remarks,
            pickup_position: am ? i : school_point, dropoff_position: am ? school_point : i, state:,
            reason: absence&.reason_text, qr_code: RiderPass.code(@occ.company_id, r.rid) }
        end
      end
    end

    def school_run
      list = SchoolRuns::Passengers.call(@occ)[:stops]
      by_name = @points.reject { it[:waypoint] }.index_by { it[:name] }
      pm = @occ.trip.session == "pm"
      school = pm ? @points.first : @points.last
      list.flat_map do |stop|
        point = by_name[stop[:name]] || school
        stop[:students].map do |st|
          { id: st[:key], name: st[:name], gender: nil, level: st[:class_name], address: nil, parent_name: st[:parent_name],
            parent_phone: st[:phone], parent_phone2: st[:phone2], note: st[:note],
            pickup_position: (pm ? school : point)[:position], dropoff_position: (pm ? point : school)[:position],
            state: st[:status], reason: nil, qr_code: nil }
        end
      end
    end
  end
end
