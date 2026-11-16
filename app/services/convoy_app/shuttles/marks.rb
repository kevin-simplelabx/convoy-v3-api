# Pin a route and switch the bell on a stop (all timings of a direction). Both are the rider's own choices, set to a value
# (not toggled), so a repeated tap never flips them back.
module ConvoyApp
  module Shuttles
    module Marks
      module_function

      def pin(account:, employer:, trip_id:, pinned:)
        Shuttles.within(employer) do
          trip = Shuttles.trip!(employer, trip_id, Time.zone.today)
          if pinned
            ShuttlePin.create_or_find_by!(app_account_id: account.id, trip_id: trip.id) { it.company_id = employer.company.id }
          else
            ShuttlePin.where(app_account_id: account.id, trip_id: trip.id).delete_all
          end
          pinned
        end
      end

      def bell(account:, employer:, trip_id:, stop_id:, direction:, on:)
        Shuttles.within(employer) do
          trip = Shuttles.trip!(employer, trip_id, Time.zone.today)
          dir = direction.to_i
          stop = trip.stops_in(dir).find { it.id == stop_id.to_i } or raise ActiveRecord::RecordNotFound
          bell = ShuttleStopBell.create_or_find_by!(app_account_id: account.id, trip_id: trip.id, trip_stop_id: stop.id, direction: dir) do
            it.company_id = employer.company.id
            it.on = on
          end
          bell.update!(on:) unless bell.on == on
          on
        end
      end
    end
  end
end
