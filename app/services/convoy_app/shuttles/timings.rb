# The runs of one route on one date, grouped by timing (a trip run): every bus of a timing (a timing with two vehicles gives
# two occurrences, a handover gives two parts), the timing's state and its strongest change. Run inside the company.
#   Timings.new(trip, date, days:, now:).list(direction) -> [Timing]
module ConvoyApp
  module Shuttles
    class Timings
      # Loaded once for the buses, drivers, stop events and times the page shows.
      INCLUDES = [ :stop_events, :school_route, :driver, :operator_driver, :replacement, { vehicle: :live_position }, { trip_run: :times }, { trip: [ { stops: :client_site }, :route_vias ] } ].freeze
      # What a timing says when its buses differ: on the road first, a pending one next, then finished, cancelled last.
      PRIORITY = %w[started on_the_way scheduled ended].freeze

      Timing = Data.define(:run, :occurrences, :state, :change, :changes)

      def initialize(trip, date, days:, now:)
        @trip = trip
        @date = date
        @days = days
        @now = now
      end

      def list(direction)
        ids = @days.runs_on(@date).select { |o| @trip.runs.find { it.id == o.trip_run_id }&.direction == direction }.map(&:id)
        return [] if ids.empty?

        TripOccurrence.where(id: ids, date: @date).includes(*INCLUDES).order(:starts_at, :slot_no, :part).to_a.group_by(&:trip_run_id).filter_map do |run_id, occs|
          run = @trip.runs.find { it.id == run_id } or next
          changes = occs.map { @days.change(it) }
          Timing.new(run:, occurrences: occs, state: state(occs), change: Change.worst(changes), changes:)
        end.sort_by { [ it.occurrences.first.start_time, it.run.position ] }
      end

      # cancelled when every bus is; else the state of the busiest bus (Portal::RunState).
      def state(occs)
        return "cancelled" if occs.all?(&:cancelled?)

        states = occs.reject(&:cancelled?).map { Portal::RunState.call(it, @now) }
        PRIORITY.find { states.include?(it) } || "scheduled"
      end
    end
  end
end
