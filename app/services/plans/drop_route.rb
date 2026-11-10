# Deletes routes of a plan with everything that hangs on them, in a few statements: stops and riders, buses, prices,
# replacement buses, run replacements (with their notifications), notice targets, and their runs on the Scheduler that have not started and have
# nothing recorded on them. Route Charges and bus request places keep their row without the route (FK nullify). A route
# with runs that started or have records (Driver app, notes, reports) stays: those runs are history.
module Plans
  class DropRoute < ApplicationService
    CHILDREN = [ SchoolRouteRider, SchoolRouteStop, SchoolRouteVehicleChange, SchoolRoutePrice, SchoolRouteReplacement, Replacement, NoticeRoute ].freeze

    def initialize(routes)
      @routes = Array(routes)
    end

    def call
      ids = @routes.map(&:id)
      return if ids.empty?

      runs = TripOccurrence.where(school_route_id: ids)
      if (kept = held(runs))
        raise Error, "#{kept.label} has runs on the Scheduler that started or have records, so it cannot be removed"
      end

      runs.delete_all
      ReplacementNotification.where(replacement_id: Replacement.where(school_route_id: ids).select(:id)).delete_all
      CHILDREN.each { it.where(school_route_id: ids).delete_all }
      SchoolRoute.where(id: ids).delete_all
    end

    private

    # The first route with a run that is history: started, or with records pointing at it (as Occurrences::Sync keeps).
    def held(runs)
      started = runs.where(starts_at: ..Time.current).distinct.pluck(:school_route_id)
      keys = runs.where(starts_at: Time.current..).pluck(:id, :date, :school_route_id)
      recorded = keys.empty? ? [] : Occurrences::Sync::RECORDS.flat_map { |m| m.where([ :occurrence_id, :occurrence_date ] => keys.map { it.first(2) }).distinct.pluck(:occurrence_id) }
      by_run = keys.to_h { [ it[0], it[2] ] }
      route_id = (started + recorded.map { by_run[it] }).compact.first
      route_id && @routes.find { it.id == route_id }
    end
  end
end
