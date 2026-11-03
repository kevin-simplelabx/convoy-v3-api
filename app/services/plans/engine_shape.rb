# A plan as the routing engine shapes a result (routes, assign, summary), for Compare (routing service /diff) and Keep
# Current. Hand-edited routes carry their re-timed engine route.
module Plans
  module EngineShape
    module_function

    def call(plan)
      routes = plan.routes.map { |r| r.engine_route || { "id" => r.route_key || "R#{r.number}", "type" => r.bus_type, "stops" => [] } }
      assign = {}
      plan.routes.each do |r|
        r.stops.each { |s| s.riders.each { |x| assign[x.rid] = { "uid" => s.stop_id.to_s, "pid" => s.stop_point_id.to_s, "route" => r.route_key, "time" => s.scheduled_time_hm } } }
      end
      { "routes" => routes, "assign" => assign, "summary" => plan.summary || summary(plan) }
    end

    def summary(plan)
      { "routes" => plan.routes.size, "byType" => plan.routes.group_by(&:bus_type).transform_values(&:size), "riders" => plan.routes.sum(&:riders_count),
        "assigned" => plan.routes.sum(&:riders_count), "unassigned" => 0, "avgJourney" => 0, "maxJourney" => 0, "avgFill" => 0, "total" => 0 }
    end
  end
end
