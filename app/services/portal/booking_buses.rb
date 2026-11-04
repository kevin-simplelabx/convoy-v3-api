# The bus assigned to each confirmed booking trip, for the Client Portal: the plates of the Scheduler runs its trip(s)
# became, on the trip's date ("Not yet. <company> assigns it after confirming" when none). { booking_trip_id => [plate] }.
module Portal
  class BookingBuses
    def self.call(trips)
      trips = trips.select(&:approved?)
      return {} if trips.empty?

      linked = Trip.kept.where(booking_trip_id: trips.map(&:id)).pluck(:id, :booking_trip_id).to_h
      dates = trips.to_h { [ it.id, it.date ] }
      runs = TripOccurrence.visible.where(trip_id: linked.keys, date: dates.values.uniq).where.not(vehicle_id: nil)
                           .joins(:vehicle).pluck(:trip_id, :date, "vehicles.plate")
      runs.each_with_object(Hash.new { |h, k| h[k] = [] }) do |(trip_id, date, plate), out|
        bt = linked[trip_id]
        out[bt] |= [ plate ] if dates[bt] == date
      end
    end
  end
end
