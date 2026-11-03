# The names on a run with names (School Bus, School Run), for the Driver app (Attendance, All Passengers, Before You
# Go) and Trip History: each child with their pick-up and drop-off point (positions on Occurrences::Stops.detailed),
# what was recorded (occurrence_passengers: when and how they boarded and alighted, who marked it) and their state:
#   expected          on the list, not ticked yet
#   bus_not_required  the parent said so (Convoy App); School Bus only
#   not_boarding      marked before the trip (Edit Route)
#   boarded, not_boarded (ticked as not there), alighted
# School Bus: the route's riders and their Bus Not Required; each has a QR boarding pass code. School Run: the route list
# the company uploaded. Other runs carry no names (counts only): [].
module Occurrences
  class Passengers < ApplicationService
    def initialize(occ, points:)
      @occ = occ
      @points = points
      @marks = occ.passenger_marks.index_by(&:passenger_key)
    end

    def call
      if @occ.school_route then school_bus
      elsif @occ.trip&.school_run? then school_run
      else []
      end
    end

    # A School Bus run's list in the shape of the School Run Passenger List (SchoolRuns::Passengers): every stop with the
    # children of that stop (their pick-up in the morning, their drop-off in the afternoon) — for Trip History.
    def self.stop_list(occ)
      points = Stops.detailed(occ)
      rows = call(occ, points:)
      school = points.find { it[:school] }&.dig(:position)
      {
        list: occ.school_route.plan.name,
        stops: points.reject { it[:school] }.map do |p|
          kids = rows.select { (it[:pickup_position] == school ? it[:dropoff_position] : it[:pickup_position]) == p[:position] }
          { name: p[:name], time: p[:planned_time], students: kids.map { student(it) } }
        end
      }
    end

    def self.student(row)
      { key: row[:id], name: row[:name], class_name: row[:level], parent_name: row[:parent_name], phone: row[:parent_phone],
        phone2: row[:parent_phone2], note: row[:note], status: row[:state], reason: row[:reason], boarded_at: row[:boarded_at],
        board_method: row[:board_method], alighted_at: row[:alighted_at], alight_method: row[:alight_method], by: row[:marked_by] }
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
      route.stops.each_with_index.flat_map do |stop, i|
        stop.riders.sort_by(&:rid).map do |r|
          rider = info[r.rid]
          absence = absences[r.rid]&.then { it.covers?(plan.session) ? it : nil }
          mark = @marks[r.rid]
          # what was marked on the run wins (a child who came after all), then the parent's Bus Not Required
          { id: r.rid, name: rider&.name || r.rid, gender: rider&.gender, level: rider&.grade, address: rider&.address,
            parent_name: rider&.parent_name, parent_phone: rider&.parent_contact, parent_phone2: nil, note: rider&.remarks,
            pickup_position: am ? i : school_point, dropoff_position: am ? school_point : i,
            state: mark&.state || (absence ? "bus_not_required" : "expected"), reason: absence&.reason_text,
            qr_code: DriverApp::RiderPass.code(@occ.company_id, r.rid), **recorded(mark) }
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
            state: st[:status], reason: nil, qr_code: nil, **recorded(@marks[st[:key]]) }
        end
      end
    end

    def recorded(mark)
      { boarded_at: mark&.boarded_at, board_method: mark&.board_method, alighted_at: mark&.alighted_at, alight_method: mark&.alight_method,
        marked_by: mark&.marked_by }
    end
  end
end
