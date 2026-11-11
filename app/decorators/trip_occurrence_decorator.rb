class TripOccurrenceDecorator < ApplicationDecorator
  # Stable key of the run for the front end (same across re-syncs): t<trip>|date|run|slot|part or r<route>|date|0|1|1.
  def key = [ trip_id ? "t#{trip_id}" : "r#{school_route_id}", date.iso8601, trip_run_id || 0, slot_no, part ].join("|")

  def driver_info
    if driver then { kind: "own", id: driver.id, name: driver.name, phone: driver.phone, photo: driver.decorate.photo_thumb }
    elsif operator_driver then { kind: "operator", id: operator_driver.id, name: operator_driver.name, phone: operator_driver.phone, photo: operator_driver.decorate.photo_thumb }
    elsif driver_name.present? then { kind: "replacement", id: nil, name: driver_name, phone: driver_phone, photo: nil }
    elsif vehicle&.driver_name.present? then { kind: "external", id: nil, name: vehicle.driver_name, phone: vehicle.driver_phone, photo: nil }
    end
  end

  # The vehicle type this slot asks for (requirements in order, one per vehicle): "No vehicle" rows show it.
  def required_vehicle_type
    return nil unless trip

    trip.vehicle_requirements.sort_by(&:id).flat_map { |r| [ r.vehicle_type ] * r.count }[slot_no - 1]&.name
  end

  def customer = trip ? trip.service_for.presence || client&.name : client&.name

  def ends_next_day = end_time >= 1440
  def title = school_route ? school_route.title : trip.title
  def route_text = school_route ? "#{school_route.plan.session_name} | #{pax} riders" : trip.decorate.route_text
  # The run's stops in travel order, [{ name, address, use, time }] (hover card; the front end also builds "A > +N > B" from them,
  # format.js routeSum / street). `use` is pu / do / both / via. `time` is "HH:MM" or nil: a shuttle run's time at the stop; on
  # other trips the stop's own time, else the run start on the first stop and the end on the last; none on a handover's second part.
  # School Bus route runs list their stops with `riders`, and the school (last on AM, first on PM).
  def route_stops
    return school_route_stops if school_route
    return [] unless trip

    stops = trip.stops_in(trip_run&.direction || 1)
    times = stop_times(stops)
    stops.each_with_index.map { |s, i| { name: s.name, address: s.address, use: s.use, time: Clock.hm(times[i]) } }
  end

  def recurring = school_route ? true : trip.recurring?
  def color = trip&.color
  def school = school_route&.plan&.school

  # Drawer of a School Bus route run: school, plan, regular bus, attendant, stops with riders.
  def route_detail
    return nil unless school_route

    r = school_route
    regular = r.regular_vehicle_id(date)
    {
      school: { id: school.id, name: school.name, short_name: school.short }, plan: { id: r.plan.id, name: r.plan.name, session: r.plan.session_name },
      label: r.label, riders: r.riders_count, regular_vehicle_id: regular, regular_plate: regular && Vehicle.find_by(id: regular)&.plate,
      attendant: r.attendant&.slice(:id, :name, :phone),
      replacement: route_replacement,
      stops: r.stops.map { |s| { name: s.name, time: s.scheduled_time_hm, riders: s.riders_count, lat: s.lat, lng: s.lng } }
    }
  end

  private

  # The route's replacement bus for this date (the box in the drawer, "Covered by <plate>"): `plate` and `operator` are the covering
  # bus's.
  def route_replacement
    rep = school_route.replacement_on(date)
    return nil unless rep

    rep.slice(:id, :vehicle_id, :starts_on, :ends_on, :arranged_by, :daily_rate, :reason)
       .merge(plate: rep.vehicle.plate, operator: rep.vehicle.operator&.slice(:id, :name))
  end

  # Minutes at each stop on this date, moved with the run (Today Only shift, calendar change).
  def stop_times(stops)
    return [] if part > 1

    base = trip_run&.start_time || trip.start_time
    times = trip_run ? trip_run.stop_minutes : stops.map(&:scheduled_time)
    unless trip_run || stops.size < 2
      times[0] ||= base
      times[-1] ||= trip.end_time
    end
    times.map { it && it + start_time - base }
  end

  def school_route_stops
    am = school_route.plan.session_am?
    list = school_route.stops.map { |s| { name: s.name, address: nil, use: am ? "pu" : "do", time: Clock.hm(s.scheduled_time), riders: s.riders_count } }
    school = { name: self.school.name, address: self.school.address, use: am ? "do" : "pu", time: Clock.hm(am ? end_time : start_time), riders: nil }
    am ? list + [ school ] : [ school ] + list
  end
end
