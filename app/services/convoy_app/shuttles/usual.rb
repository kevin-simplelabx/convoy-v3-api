# Convoy App › Shuttles › My Usual Shuttle sheet: the routes with their directions, timings and boarding stops (`options`), and
# Save as My Usual / Clear. One per employer. The stop falls back to the first boarding stop; the timing is required.
module ConvoyApp
  module Shuttles
    module Usual
      module_function

      # { routes: [{ id, name, directions: [{ direction, name, timings: [{ run_id, time }], stops: [{ id, name }] }] }], usual: }
      def options(account:, employer:)
        Shuttles.within(employer) do
          trips = Shuttles.trips(employer, Time.zone.today).to_a.select { Shuttles.directions(it).any? }
          usual = UsualOf.for(account, employer.client)
          { employer: employer.json, usual: usual.present? ? { trip_id: usual.trip_id, run_id: usual.run_id, stop_id: usual.stop_id, direction: usual.direction } : nil,
            routes: trips.map do |t|
              { id: t.id, name: t.title,
                directions: Shuttles.directions(t).map { |d| { direction: d, name: DIRECTIONS.fetch(d), timings: runs(t, d), stops: boarding(t, d) } } }
            end }
        end
      end

      # Save as My Usual: trip_id, run_id (the timing), stop_id (where you board; optional). Returns the saved usual.
      def save(account:, employer:, trip_id:, run_id:, stop_id: nil)
        Shuttles.within(employer) do
          trip = Shuttles.trip!(employer, trip_id, Time.zone.today)
          run = trip.runs.find { it.id == run_id.to_i } or raise ApplicationService::Error, "Pick your usual timing"
          stops = boarding_stops(trip, run.direction)
          stop = stop_id.present? ? stops.find { it.id == stop_id.to_i } : stops.first
          raise ApplicationService::Error, "Pick where you board" unless stop

          record = ShuttleUsual.find_or_initialize_by(app_account_id: account.id, client_id: employer.client.id)
          record.update!(company_id: employer.company.id, trip:, trip_run: run, trip_stop: stop)
          record
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      def clear(account:, employer:)
        Shuttles.within(employer) { ShuttleUsual.where(app_account_id: account.id, client_id: employer.client.id).destroy_all }
      end

      def runs(trip, direction)
        trip.runs.select { it.direction == direction }.sort_by(&:position).map { { run_id: it.id, time: Shuttles.hm(it.start_time) } }
      end

      def boarding_stops(trip, direction) = trip.stops_in(direction).select { it.use_in(direction).in?(%w[pu both]) }

      def boarding(trip, direction) = boarding_stops(trip, direction).map { { id: it.id, name: it.name_in(direction) } }
    end
  end
end
