# Lists future runs whose stored values differ from the generator (missing, extra, or changed), for rake occurrences:verify.
module Occurrences
  class Verify < ApplicationService
    def call
      from = Date.current
      to = Sync.horizon
      trips = Trip.kept.includes(*Sync::TRIP_INCLUDES).to_a
      gen = Generator.new(context: Calendars::Context.for(ActsAsTenant.current_tenant, from:, to:), fleet: Fleet.new)
      now = Time.current
      saved = TripOccurrence.where(date: from..to).index_by(&:identity)
      routes = SchoolRoute.joins(:plan).merge(SchoolPlan.running_between(from, to)).includes(*Sync::ROUTE_INCLUDES).to_a
      route_gen = RouteGenerator.new(context: Calendars::Context.for(ActsAsTenant.current_tenant, from:, to:), fleet: Fleet.new)
      desired = (trips.flat_map { |t| gen.rows(t, [ from, t.starts_on ].max, to, existing: saved) } +
                 routes.flat_map { |r| route_gen.rows(r, from, to, existing: saved) }).select { |r| r.starts_at > now }.index_by(&:identity)
      stored = saved.values.reject(&:removed?).select { |o| o.starts_at > now }.index_by(&:identity)
      out = []
      desired.each do |key, row|
        occ = stored.delete(key)
        if occ.nil? then out << "missing #{row.trip_label} #{row.date}"
        elsif occ.source_digest != row.digest then out << "changed #{occ.trip_label} #{occ.date}"
        end
      end
      stored.each_value { |o| out << "extra #{o.trip_label} #{o.date}" }
      out
    end
  end
end
