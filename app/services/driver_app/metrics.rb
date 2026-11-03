# Career Metrics (Account): completed runs, hours driven and distance, for each company record of the driver; the app
# shows This Company (the picked one) and All Time (every company). Hours = started → ended in the app, else the planned
# times; distance = the GPS trip summary where there is one. Returns { "driver-4" => { trips:, hours:, km: } }.
module DriverApp
  class Metrics < ApplicationService
    ZERO = { trips: 0, hours: 0.0, km: 0.0 }.freeze

    def initialize(members:)
      @members = members
    end

    def call
      return {} if @members.empty?

      ids = @members.group_by(&:class).transform_values { it.map(&:id) }
      rows = ActsAsTenant.without_tenant do
        scope = TripOccurrence.where(status: "completed")
        scope = [ [ Driver, :driver_id ], [ OperatorDriver, :operator_driver_id ] ].filter_map { |klass, col| ids[klass] && scope.where(col => ids[klass]) }.reduce(:or)
        scope.left_joins(:trip_summary).group(:driver_id, :operator_driver_id).pluck(
          :driver_id, :operator_driver_id, Arel.sql("COUNT(*)"),
          Arel.sql("SUM(EXTRACT(EPOCH FROM COALESCE(trip_occurrences.ended_at, trip_occurrences.ends_at) - COALESCE(trip_occurrences.started_at, trip_occurrences.starts_at)))"),
          Arel.sql("SUM(occurrence_trip_summaries.distance_km)")
        )
      end
      rows.to_h do |driver_id, operator_driver_id, trips, seconds, km|
        key = driver_id ? "driver-#{driver_id}" : "operator_driver-#{operator_driver_id}"
        [ key, { trips:, hours: (seconds.to_f / 3600).round(1), km: km.to_f.round(1) } ]
      end
    end

    # { this_company:, all_time: } for the Account screen.
    def self.summary(members:, current_key:)
      per = call(members:)
      all = per.values.reduce(ZERO.dup) { |sum, m| sum.merge(m) { |_k, a, b| a + b } }
      { this_company: per[current_key] || ZERO, all_time: all.merge(hours: all[:hours].round(1), km: all[:km].round(1)) }
    end
  end
end
