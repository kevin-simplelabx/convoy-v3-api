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
  # The run's stops in travel order, [{ name, address }]: the front end builds "A > +N > B" (format.js routeSum / street)
  # from them. School Bus route runs have none (route_text says session and riders).
  def route_stops
    return [] unless trip

    trip.stops_in(trip_run&.direction || 1).map { |s| { name: s.name, address: s.address } }
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
      replacement: r.replacement_on(date)&.slice(:id, :vehicle_id, :starts_on, :ends_on, :arranged_by, :daily_rate, :reason),
      stops: r.stops.map { |s| { name: s.name, time: s.scheduled_time_hm, riders: s.riders_count, lat: s.lat, lng: s.lng } }
    }
  end
end
