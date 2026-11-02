# The runs a replacement touches: the one run, or every run on the original bus in its dates (part 1, not cancelled).
module Replacements
  module Affected
    module_function

    def runs(rep)
      scope = TripOccurrence.visible.where.not(status: "cancelled").where(part: 1)
      if rep.for_run?
        scope.where(trip_id: rep.trip_id, school_route_id: rep.school_route_id, date: rep.run_date, trip_run_id: rep.trip_run_id, slot_no: rep.slot_no)
      else
        scope.where(date: rep.starts_on..rep.ends_on)
             .where("vehicle_id = :v OR original_vehicle_id = :v", v: rep.original_vehicle_id)
      end
    end

    # Trips and dates to re-sync: what it covers now and what it covered before the change.
    def resync(rep, before: nil)
      now = snapshot(rep)
      trips = now[:trip_ids] | (before&.dig(:trip_ids) || [])
      routes = now[:route_ids] | (before&.dig(:route_ids) || [])
      from = [ rep.starts_on, before&.dig(:from) ].compact.min
      to = [ rep.ends_on, before&.dig(:to) ].compact.max
      return if trips.empty? && routes.empty?

      Occurrences::Sync.call(trips:, routes:, from: [ from, Date.current ].max, to:)
    end

    def snapshot(rep)
      list = runs(rep)
      { trip_ids: list.where.not(trip_id: nil).distinct.pluck(:trip_id), route_ids: list.where.not(school_route_id: nil).distinct.pluck(:school_route_id),
        from: rep.starts_on, to: rep.ends_on }
    end
  end
end
