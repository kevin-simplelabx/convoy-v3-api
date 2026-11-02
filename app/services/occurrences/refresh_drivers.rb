# A vehicle's driver changed (default driver schedule, operator driver put on or taken off the bus): re-syncs, from a date,
# the trips and routes with runs on that vehicle (or ghosted from it) that have not started. Going through Sync keeps
# replacements on top (a Driver Away still wins over the new default driver).
module Occurrences
  class RefreshDrivers < ApplicationService
    def initialize(vehicle_id:, from:)
      @vehicle_id = vehicle_id
      @from = [ from, Date.current ].max
    end

    def call
      runs = TripOccurrence.where(vehicle_id: @vehicle_id).or(TripOccurrence.where(original_vehicle_id: @vehicle_id))
                           .where(date: @from..).where("starts_at > ?", Time.current)
      trips = runs.where.not(trip_id: nil).distinct.pluck(:trip_id)
      routes = runs.where.not(school_route_id: nil).distinct.pluck(:school_route_id)
      Sync.call(trips:, routes:, from: @from)
    end
  end
end
