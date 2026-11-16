# The Scheduler runs confirmed booking trips became (Bookings::Approve: one trip, or an outbound and its return, with one
# run per bus on the trip's date), loaded at once for a page of bookings. Inside `within`.
#   runs = Runs.load(bookings); runs.for(booking_trip) -> [TripOccurrence] (way there first, then by bus)
module ConvoyApp
  module Bookings
    class Runs
      INCLUDES = [ :stop_events, :driver, :operator_driver, { vehicle: :live_position, trip: :stops, trip_run: :times } ].freeze

      def self.load(bookings, now: Time.current) = new(bookings, now)

      attr_reader :now

      def initialize(bookings, now)
        @now = now
        trips = Array(bookings).flat_map { it.trips.to_a }.select(&:approved?)
        dates = trips.to_h { [ it.id, it.date ] }
        linked = trips.empty? ? [] : Trip.kept.where(booking_trip_id: trips.map(&:id)).pluck(:id, :booking_trip_id)
        by_trip = linked.to_h
        runs = linked.empty? ? [] : TripOccurrence.visible.where(trip_id: by_trip.keys, date: dates.values.uniq).includes(*INCLUDES).to_a
        @runs = runs.select { dates[by_trip[it.trip_id]] == it.date }
                    .group_by { by_trip[it.trip_id] }
                    .transform_values { |list| list.sort_by { [ it.trip.is_return ? 1 : 0, it.starts_at, it.slot_no.to_i ] } }
      end

      def for(trip) = @runs.fetch(trip.id, [])

      # Runs of the way there (one per bus).
      def out(trip) = self.for(trip).reject { it.trip.is_return }

      def live?(trip) = self.for(trip).any? { Portal::RunState.on_road?(Portal::RunState.call(it, @now)) }
      def ended?(trip) = self.for(trip).any? && self.for(trip).all? { Portal::RunState.call(it, @now) == "ended" }

      # What the trip's runs are worth (the client price of each run not cancelled): the confirmed price.
      def price(trip)
        list = self.for(trip).reject(&:cancelled?)
        list.empty? ? nil : list.sum(&:price)
      end
    end
  end
end
