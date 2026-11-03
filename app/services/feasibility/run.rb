# Plan a feasibility scenario (port of fzRun): place the postal codes (OneMap), make each student a rider, group them by
# home postal code (door-to-door) or by the nearest Stop Library PUDO within the walk, and plan AM and PM in the routing
# service with the scenario's bus sizes, attendants, ride limits and parameter overrides. The result keeps each
# session's routes and unassigned riders, and which students are served both ways (sv: "postal|session" => n).
module Feasibility
  class Run < ApplicationService
    def initialize(scenario)
      @sc = scenario
      @study = scenario.feasibility_study
    end

    def call
      place = @study.place or raise Error, "Set the school location first"
      raise Error, "Add student postal codes first" if @study.rows.empty?
      raise Error, "Pick at least one bus size" if @sc.sizes.empty?

      geo = locate
      students = @study.rows.flat_map { |r| Array.new(r.riders) { { postal: r.postal, session: r.session } } }.each_with_index.map { |s, i| s.merge(rid: "fz#{i + 1}") }
      near = @study.pickup == "lib" ? nearest_points(geo) : {}
      out = { "need" => students.size }
      %w[AM PM].each do |se|
        list = students.select { it[:session] == "both" || it[:session] == se }
        next if list.empty?

        out[se] = plan(se, list, place, geo, near)
      end
      served = students.select { |s| (s[:session] == "PM" || ids(out, "AM").include?(s[:rid])) && (s[:session] == "AM" || ids(out, "PM").include?(s[:rid])) }
      out["served"] = served.size
      out["sv"] = served.group_by { "#{it[:postal]}|#{it[:session]}" }.transform_values(&:size)
      %w[AM PM].each { out[it]&.delete("ids") }
      out
    end

    private

    def ids(out, se) = Array(out.dig(se, "ids")).to_set

    def locate
      postals = @study.rows.map(&:postal).uniq
      missing = 0
      geo = postals.to_h do |pc|
        point = Geo::OneMap.lookup(pc)
        [ pc, point ]
      rescue Geo::OneMap::Unavailable
        missing += 1
        [ pc, :unknown ]
      end
      raise Error, "#{missing} postal code#{'s' unless missing == 1} could not be checked on OneMap. Run again in a moment" if missing.positive?

      geo
    end

    def nearest_points(geo)
      points = StopPoint.where(retired_at: nil, stop: Stop.kept.where(library_status: "approved")).includes(:stop).to_a
      geo.compact.transform_values do |g|
        best = points.min_by { Geo.metres([ g[:lat], g[:lng] ], [ it.lat, it.lng ]) }
        best if best && Geo.metres([ g[:lat], g[:lng] ], [ best.lat, best.lng ]) <= @study.walk_m
      end.compact
    end

    def plan(se, list, place, geo, near)
      groups = {}
      no_stop = []
      list.each do |s|
        g = geo[s[:postal]]
        next no_stop << { rid: s[:rid], name: s[:postal] } unless g

        p = near[s[:postal]]
        key = p ? "L#{p.id}" : "P#{s[:postal]}"
        groups[key] ||= { uid: key, stopId: p ? p.stop.code : s[:postal], name: p ? p.stop.name : (g[:address].presence || s[:postal]), riders: [],
                          points: [ { pid: key, sfx: p ? p.suffix : "A", label: p ? p.pudo_code : s[:postal], lat: (p ? p.lat : g[:lat]).to_f,
                                      lng: (p ? p.lng : g[:lng]).to_f, usage: "both", sizes: p&.sizes.presence || %w[S M L] } ] }
        groups[key][:riders] << s[:rid]
      end
      res = Routing::Client.current.solve({ school: place, groups: groups.values, noStop: no_stop, conflicts: [], current: nil, params: params(se) })
      return { "fail" => Array(res["validation"]).select { it["level"] == "Error" }.map { it["msg"] } } if res["status"] == "FAILED"

      postal = list.to_h { [ it[:rid], it[:postal] ] }
      { "ids" => res["assign"].keys,
        "summary" => res["summary"].slice("routes", "assigned", "unassigned", "avgJourney", "maxJourney", "avgFill"),
        "routes" => res["routes"].map do |r|
          { "id" => r["id"], "type" => r["type"], "label" => r["label"], "attendant" => !!r["attendant"], "load" => r["load"], "seats" => r["studentSeats"],
            "minutes" => (r["span"].to_f / 60).round, "startT" => r["startT"], "endT" => r["endT"],
            "stops" => r["stops"].map { |z| { "ll" => z["ll"], "n" => z["n"], "time" => z["time"], "name" => z["name"], "postals" => postals_of(z["riders"], postal) } } }
        end,
        "unassigned" => Array(res["unassigned"]).map { it.slice("n", "reason", "label") } }
    rescue Routing::Client::Unavailable => e
      raise Error, "The routing service is not available (#{e.message})"
    end

    def postals_of(rids, postal)
      Array(rids).filter_map { postal[it] }.tally.map { |pc, n| n > 1 ? "#{pc} x#{n}" : pc }.join(", ")
    end

    def params(se)
      base = (RoutingSetting.first&.params || {}).merge(@sc.params.compact_blank)
      types = Array(base["types"].presence || Routing::Client.current.meta["types"]).map { it.merge("on" => @sc.sizes.include?(it["type"])) }
      base.merge("session" => se, "attendant" => @sc.attendant, "attSizes" => [], "hardCap" => @sc.hard_cap, "targetCap" => @sc.target_cap, "types" => types)
    end
  end
end
