# The rider's usual shuttle at an employer as a small object: the route, timing and boarding stop, and whether a place on a route
# is "theirs" (the usual boarding stop gets the bell by default, "My Stop" shows on the usual run).
module ConvoyApp
  module Shuttles
    UsualOf = Data.define(:record) do
      def self.for(account, client) = new(ShuttleUsual.includes(:trip_run).find_by(app_account_id: account.id, client_id: client.id))

      def present? = record.present?
      def trip_id = record&.trip_id
      def run_id = record&.trip_run_id
      def stop_id = record&.trip_stop_id
      def direction = record&.trip_run&.direction

      # The usual boarding stop of this route and direction (the default bell).
      def stop_in?(trip, dir) = present? && trip_id == trip.id && direction == dir

      def run?(run) = present? && run_id == run.id
    end
  end
end
