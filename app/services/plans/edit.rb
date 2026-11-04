# Hand edits on a plan (route drawer and map tools), each re-timed by the routing service (/retime) as Convoy OS does:
# a route's stops in travel order with their riders (reorder, move a stop or a rider here, add or remove riders, via
# points), a new route from stops (locked, manual), a route's bus type, deleting a route, resetting a route to the
# engine's. A rider placed on a route leaves any other route of the plan and the unassigned list; a rider taken off
# goes to the unassigned list. The plan's summary follows; runs of an adopted plan are re-synced.
module Plans
  class Edit
    def initialize(plan)
      @plan = plan
      @school = plan.school
    end

    # entries: [{ stop_point_id, riders: [rid] }] in travel order; vias: [[[lat, lng], …] per leg]
    def set_stops(route, entries, vias: nil, type: nil)
      raise ApplicationService::Error, "A route needs at least one stop with riders" if entries.empty?

      stops = engine_stops(entries)
      SchoolPlan.transaction do
        before = route.riders.pluck(:rid)
        placed = stops.flat_map { it[:riders] }
        take_from_others(route, placed)
        retime(route, stops, vias:, type:)
        route.update!(edited: true, vias: vias || route.vias)
        unassign(before - placed, "Removed by hand")
        finish(placed)
      end
      route
    end

    def add_route(entries, type:)
      number = (@plan.routes.maximum(:number) || 0) + 1
      route = @plan.routes.build(number:, label: Plans.label(@school, @plan.session, number), route_key: format("R%02d", number), bus_type: type,
                                 manual: true, locked: true, start_time: 0, end_time: 1)
      set_stops(route, entries, type:)
    end

    def change_type(route, type)
      stops = route.engine_route&.dig("stops") || []
      raise ApplicationService::Error, "Add stops to the route first" if stops.empty?

      SchoolPlan.transaction do
        retime(route, stops.map(&:symbolize_keys), vias: route.vias, type:)
        route.update!(edited: true)
        finish([])
      end
      route
    end

    def remove_route(route)
      SchoolPlan.transaction do
        unassign(route.riders.pluck(:rid), "Route deleted")
        drop(route)
        finish([])
      end
    end

    # Optimise / Optimise All: each route's stops in the order that costs least (routing service, as Convoy OS bestOrder);
    # via points stay on the legs that still join the same stops. Returns the message to show.
    def optimise(routes)
      list = routes.select { Array(it.engine_route&.dig("stops")).size >= 2 }
      out = list.empty? ? [] : Array(Routing::Client.current.optimise(routes: list.map { { id: it.id, base: it.engine_route, stops: it.engine_route["stops"] } },
                                                                      school: { lat: @school.lat.to_f, lng: @school.lng.to_f }, params:)["routes"])
      SchoolPlan.transaction do
        out.each do |o|
          route = list.find { it.id == o["id"] } or next
          stops = route.engine_route["stops"].map(&:symbolize_keys)
          ordered = o["order"].map { stops[it] }
          retime(route, ordered, vias: keep_vias(stops, ordered, route.vias))
          route.update!(edited: true, vias: keep_vias(stops, ordered, route.vias))
        end
        finish([]) if out.any?
      end
      optimise_message(routes, list, out)
    rescue Routing::Client::Unavailable => e
      raise ApplicationService::Error, "The routing service is not available (#{e.message})"
    end

    # Reset All: routes drawn by hand go, every other route goes back to the engine's result, and so does the unassigned list.
    def reset_all
      result = @plan.routing_run&.result
      raise ApplicationService::Error, "This plan was not made by the routing engine, so there is nothing to reset to" unless result

      keys = Array(result["routes"]).map { it["id"] }
      SchoolPlan.transaction do
        @plan.routes.reject { !it.manual && keys.include?(it.route_key) }.each { drop(it) }
        SchoolRouteRider.where(school_route_id: @plan.routes.reload.select(:id)).delete_all
        by_key = @plan.routes.includes(:stops).index_by(&:route_key)
        number = @plan.routes.maximum(:number).to_i
        Array(result["routes"]).each do |er|
          route = by_key[er["id"]] || @plan.routes.build(number: number += 1, label: Plans.label(@school, @plan.session, number))
          Plans.write_route(route, er)
          route.update!(edited: false, vias: [])
        end
        @plan.update!(unassigned: result["unassigned"] || [])
        finish(result["routes"].to_a.flat_map { |er| Array(er["stops"]).flat_map { Array(it["riders"]) } })
      end
      "All manual edits cleared, including routes drawn by hand"
    end

    def reset(route)
      original = Array(@plan.routing_run&.result&.dig("routes")).find { it["id"] == route.route_key }
      raise ApplicationService::Error, "#{route.label} was drawn by hand, so there is nothing to reset to" unless original

      SchoolPlan.transaction do
        before = route.riders.pluck(:rid)
        rids = Array(original["stops"]).flat_map { it["riders"] }
        take_from_others(route, rids)
        Plans.write_route(route, original)
        route.update!(edited: false, vias: [])
        unassign(before - rids, "Taken off by Reset Route")
        finish(rids)
      end
      route
    end

    private

    # Via points of a leg kept when the leg still joins the same two stops (the last leg of a morning route ends at the school).
    def keep_vias(old, now, vias)
      return [] if vias.blank?

      key = ->(list, k) { [ list[k][:pid], list[k + 1]&.dig(:pid) || "school" ] }
      before = old.each_index.to_h { [ key.(old, it), vias[it] ] }
      now.each_index.map { before[key.(now, it)] || [] }
    end

    def optimise_message(routes, list, out)
      if routes.size == 1
        r = routes.first
        o = out.first or return "#{r.label} is already in the best order for its passengers"
        avg = ->(m) { (m.to_f / [ r.riders_count.to_i, 1 ].max).round }
        "#{r.label} re-ordered. Journey #{(o.dig('before', 'span').to_f / 60).round} to #{(o.dig('after', 'span').to_f / 60).round} min, " \
          "avg ride #{avg.(o.dig('before', 'ride'))} to #{avg.(o.dig('after', 'ride'))} min"
      elsif out.empty? then "Every route is already in its best stop order"
      else
        saved = out.sum { it.dig("before", "span").to_f - it.dig("after", "span").to_f }
        labels = out.map { |o| list.find { it.id == o["id"] }&.label }.compact
        "#{out.size} route#{'s' unless out.size == 1} re-ordered (#{labels.join(', ')}). #{(saved / 60).round} bus-min saved"
      end
    end

    def engine_stops(entries)
      points = StopPoint.where(id: entries.map { it[:stop_point_id] }, stop: Stop.visible_to(@school)).includes(:stop).index_by(&:id)
      known = SchoolRider.where(school: @school, rid: entries.flat_map { Array(it[:riders]) }).pluck(:rid).to_set
      entries.map do |e|
        p = points[e[:stop_point_id].to_i] or raise ApplicationService::Error, "Pick stops from the Stop Library"
        rids = Array(e[:riders]).map(&:to_s)
        raise ApplicationService::Error, "#{p.pudo_code}: pick riders of this school" unless rids.all? { known.include?(it) }

        { uid: p.stop_id.to_s, stopId: p.stop.code, name: p.stop.name, pid: p.id.to_s, sfx: p.suffix, ll: [ p.lat.to_f, p.lng.to_f ], n: rids.size, riders: rids }
      end
    end

    # Riders placed on this route leave the plan's other routes (re-timed; emptied routes go).
    def take_from_others(route, rids)
      return if rids.empty?

      @plan.routes.where.not(id: route.id).includes(stops: :riders).find_each do |other|
        stops = Array(other.engine_route&.dig("stops")).map(&:symbolize_keys)
        next unless stops.any? { (Array(it[:riders]) & rids).any? }

        left = stops.filter_map do |s|
          kept = Array(s[:riders]) - rids
          kept.empty? ? nil : s.merge(riders: kept, n: kept.size)
        end
        left.empty? ? drop(other) : retime(other, left, vias: nil).update!(edited: true)
      end
    end

    def retime(route, stops, vias:, type: nil)
      base = route.engine_route || { "id" => route.route_key, "type" => type || route.bus_type }
      payload = { base:, stops:, school: { lat: @school.lat.to_f, lng: @school.lng.to_f }, params:, vias: vias.presence, type: }.compact
      Plans.write_route(route, Routing::Client.current.retime(payload))
    rescue Routing::Client::Unavailable => e
      raise ApplicationService::Error, "The routing service is not available (#{e.message})"
    end

    def params = (@plan.params.presence || RoutingSetting.first&.params || {}).merge("session" => Routing::SESSION_KEYS[@plan.session])

    # A route of an adopted plan has runs on the Scheduler, so it stays (make a new plan to change the routes).
    def drop(route)
      raise ApplicationService::Error, "#{route.label} is in an adopted plan and runs on the Scheduler. Make a new plan to remove a route" if @plan.in_use

      [ SchoolRouteRider, SchoolRouteStop, SchoolRouteVehicleChange, SchoolRouteReplacement ].each { it.where(school_route_id: route.id).delete_all }
      SchoolRoute.where(id: route.id).delete_all
    end

    def unassign(rids, reason)
      return if rids.empty?

      @plan.unassigned = Array(@plan.unassigned) + [ { "riders" => rids, "n" => rids.size, "reason" => reason, "label" => reason } ]
    end

    def finish(placed)
      list = Array(@plan.unassigned).filter_map do |u|
        left = Array(u["riders"]) - placed
        left.empty? ? nil : u.merge("riders" => left, "n" => left.size)
      end
      @plan.update!(unassigned: list, summary: Plans.summary(@plan.reload, list))
      AcademicYears.resync(@school) if @plan.in_use
    end
  end
end
