# Approved booking trips: Unassigned while a Scheduler run of theirs has no vehicle (or, with no runs yet, the trip has
# no vehicle), else Assigned. Sets BookingTrip#unassigned on the loaded trips in a few queries.
module Bookings
  class Assignment
    def self.load!(bookings_or_trips)
      trips = Array(bookings_or_trips).flat_map { |x| x.is_a?(Booking) ? x.trips.to_a : [ x ] }.select(&:approved?)
      return if trips.empty?

      ids = trips.map(&:id)
      linked = Trip.kept.where(booking_trip_id: ids).pluck(:id, :booking_trip_id).to_h
      open_runs = TripOccurrence.visible.where(status: "scheduled", vehicle_id: nil, trip_id: linked.keys).distinct.pluck(:trip_id)
      with_runs = TripOccurrence.visible.where(trip_id: linked.keys).distinct.pluck(:trip_id)
      with_bus = TripVehicleSlot.where(trip_id: linked.keys).where.not(vehicle_id: nil).distinct.pluck(:trip_id)
      waiting = linked.keys.select { |id| open_runs.include?(id) || (with_runs.exclude?(id) && with_bus.exclude?(id)) }
      unassigned = waiting.map { |id| linked[id] }.to_set
      trips.each { |t| t.unassigned = unassigned.include?(t.id) }
    end
  end
end
