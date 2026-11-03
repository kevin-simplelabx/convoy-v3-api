# The points of a run in travel order, with their planned times: one place for Trip History, Live Map, Ops Control,
# reports, tracking links and the Driver app. A trip run takes its trip's stops in the run's direction (a shuttle's
# timetable, else each stop's time, else the start at the first stop) plus the run's Today Only shift; a School Bus run
# takes its route's stops. `position` is the stop's index on that list (what occurrence_stop_events record).
module Occurrences
  module Stops
    module_function

    # [{ position, name, use, planned_time, planned_minute, lat, lng, note }]
    def planned(occ) = entries(occ).map(&:first)

    # The Driver app's points: planned plus the address, notes, photos, Street View, pick-up / drop-off, the road pins
    # after the stop (vias) and, for a School Bus run, the school (last in the morning, first in the afternoon).
    def detailed(occ)
      list = entries(occ).map do |base, stop|
        base.merge(stop_details(stop, occ))
      end
      return list unless occ.school_route

      school = occ.school_route.plan.school
      am = occ.school_route.plan.session == "am"
      point = { position: list.size, name: school.name, use: am ? "do" : "pu", planned_time: Clock.hm(am ? occ.end_time : occ.start_time),
                planned_minute: am ? occ.end_time : occ.start_time, lat: school.lat, lng: school.lng, note: nil,
                address: [ school.address, school.postal && "Singapore #{school.postal}" ].compact_blank.join(", ").presence,
                school: true, pickup: !am, dropoff: am, waypoint: false, photos: [], street_view_url: nil, vias: [] }
      list.each { |s| s.merge!(pickup: am, dropoff: !am) }
      am ? list + [ point ] : [ point ] + list
    end

    def entries(occ)
      if occ.school_route
        return occ.school_route.stops.each_with_index.map do |s, i|
          [ { position: i, name: s.name, use: nil, planned_time: s.scheduled_time_hm, planned_minute: s.scheduled_time, lat: s.lat, lng: s.lng }, s ]
        end
      end
      trip = occ.trip
      return [] unless trip

      times = occ.trip_run ? occ.trip_run.stop_minutes : []
      trip.stops_in(occ.trip_run&.direction || 1).each_with_index.map do |s, i|
        minute = times[i] || s.scheduled_time || (occ.start_time - occ.shift_minutes if i.zero?)
        minute += occ.shift_minutes if minute
        [ { position: i, name: s.name, use: s.use, planned_time: Clock.hm(minute), planned_minute: minute, lat: s.lat, lng: s.lng,
            note: s.driver_note }, s ]
      end
    end

    def stop_details(stop, occ)
      return { address: nil, school: false, waypoint: false, photos: [], street_view_url: nil, vias: [] } unless stop.is_a?(TripStop)

      direction = occ.trip_run&.direction || 1
      vias = occ.trip.route_vias.select { |v| v.direction == direction && v.from_position == stop.position }
      { address: stop.address, school: false, pickup: stop.use.in?(%w[pu both]), dropoff: stop.use.in?(%w[do both]), waypoint: stop.use == "via",
        photos: stop.photos.map { it.decorate.file_info(:photo, versions: [ :thumb ]) }, street_view_url: stop.street_view_url,
        vias: vias.map { { lat: it.lat&.to_f, lng: it.lng&.to_f } } }
    end
  end
end
