# The values of a booking trip the client cares about, in words, to list what an edit changed
# ("Pick-up time: 08:00 to 09:00"), as the booking form does when it saves.
module Bookings
  class TripSummary
    def self.call(trip, date) = new(trip, date).call

    def self.changes(before, after)
      before.filter_map { |label, old| "#{label}: #{old.presence || 'none'} to #{after[label].presence || 'none'}" if old.to_s != after[label].to_s }
    end

    def initialize(trip, date)
      @trip = trip
      @date = date
    end

    def call
      out = @trip.points.select { |p| p.leg == "out" }.sort_by(&:position)
      {
        "Date" => @date&.strftime("%d/%m/%Y"), "Trip type" => @trip.kind_name, "Pick-up time" => @trip.start_time_hm,
        "Return time" => @trip.return_time_hm, "Hours" => @trip.hours&.to_d&.to_s("F"), "Pick-up" => out.first&.name,
        "Drop-off" => (out.last&.name if out.size > 1), "Stops" => out[1...-1].to_a.map(&:name).join(", "),
        "Flight" => @trip.flight_number, "Passengers" => @trip.pax.to_s, "Luggage" => luggage, "Vehicles" => vehicles
      }
    end

    private

    def luggage
      { "Large" => @trip.luggage_large, "Medium" => @trip.luggage_medium, "Cabin" => @trip.luggage_cabin, "Extra Large" => @trip.luggage_extra_large,
        "Oversized" => @trip.luggage_oversized }.filter_map { |name, n| "#{n} #{name}" if n.to_i.positive? }.join(", ")
    end

    def vehicles
      @trip.vehicles.sort_by(&:vehicle_type_id).map { |v| "#{v.count} x #{v.vehicle_type.name}" }.join(", ")
    end
  end
end
