# School Bus route plans: made from a routing run or drawn by hand, edited, compared and adopted.
module Plans
  module_function

  # "AM Plan 3": the next number among the school's plans of the session.
  def next_name(school, session) = "#{SchoolPlan::SESSIONS[session]} Plan #{school.plans.where(session:).count + 1}"

  # Route label of the n-th route of a session from the school's Route Labels.
  def label(school, session, n) = school.labels.find { it.session == session }.label(n)

  # Re-sync the runs of these plans' routes on the Scheduler (from today on), e.g. after an adoption moved their dates.
  def resync(*plans)
    plans = plans.compact
    routes = SchoolRoute.where(school_plan_id: plans.map(&:id)).pluck(:id)
    OccurrenceSyncJob.perform_later(plans.first.company_id, [], Date.current.iso8601, nil, routes) if routes.any?
  end

  # A plan's figures from its routes (after hand edits, Route Again or Draw Routes), as the engine's summarize: counts,
  # journeys, fill, the optimisation score by part (each route's engine cost) and total, and buses per 5-minute slot
  # (arrival at school for AM, departure for the others). Nothing is kept from an older summary.
  def summary(plan, unassigned = plan.unassigned)
    routes = plan.routes.to_a
    spans = routes.map { it.span_seconds.to_f / 60 }
    riders = routes.sum(&:riders_count)
    left = Array(unassigned).sum { it["n"] || Array(it["riders"]).size }
    cost = ->(k) { routes.sum(0.0) { it.engine_route&.dig("cost", k).to_f } }
    s = { "riders" => riders + left, "assigned" => riders, "unassigned" => left, "routes" => routes.size,
          "byType" => routes.group_by(&:bus_type).transform_values(&:size), "avgJourney" => spans.any? ? spans.sum / spans.size : 0,
          "maxJourney" => spans.max || 0, "avgFill" => routes.any? ? routes.sum { it.fill.to_f } / routes.size : 0,
          "fixed" => cost.("fixed"), "run" => cost.("run"), "overtime" => cost.("overtime"), "floor" => cost.("floor"), "stability" => cost.("stability"),
          "slots" => routes.map { slot(it, plan.session_am?) }.tally }
    s.merge("total" => s["fixed"] + s["run"] + s["overtime"] + s["floor"])
  end

  # "07:25": the 5-minute slot a route reaches school (AM) or leaves it, as the engine keys slots.
  def slot(route, am)
    sec = route.engine_route&.dig(am ? "end" : "start") || ((am ? route.end_time : route.start_time).to_i * 60)
    Clock.hm((sec.to_i / 300 * 300) / 60)
  end

  # Writes an engine route (as the engine shapes it) into a plan route and its stops and riders.
  def write_route(route, er)
    route.assign_attributes(
      route_key: er["id"], bus_type: er["type"], seats: er["seats"], student_seats: er["studentSeats"], capacity: er["cap"], floor: er["floor"],
      fill: er["fill"]&.round(4), span_seconds: er["span"]&.round, ride_minutes: er["rideMin"], badges: Array(er["badges"]), engine_route: er,
      riders_count: er["load"].to_i, start_time: er["startT"], end_time: er["endT"]
    )
    route.end_time = route.start_time + 1 if route.start_time && route.end_time && route.end_time <= route.start_time
    route.save!
    route.stops.destroy_all
    Array(er["stops"]).each_with_index do |s, i|
      stop = route.stops.create!(position: i, name: s["name"].presence || s["stopId"].to_s, lat: s.dig("ll", 0), lng: s.dig("ll", 1), scheduled_time: s["time"],
                                 riders_count: s["n"].to_i, dwell_seconds: s["dwell"]&.round, stop_id: s["uid"].presence&.to_i, stop_point_id: s["pid"].presence&.to_i)
      Array(s["riders"]).each { |rid| stop.riders.create!(school_route: route, rid:) }
    end
    route
  end
end
