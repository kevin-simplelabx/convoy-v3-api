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

    # What must be true before a run starts (the controller checks it before answering 202, the run again before planning).
    def self.check!(scenario)
      study = scenario.feasibility_study
      study.place or raise Error, "Set the school location first"
      raise Error, "Add student postal codes first" unless study.rows.exists?
      raise Error, "Pick at least one bus size" if scenario.sizes.empty?
    end

    def call
      self.class.check!(@sc)
      place = @study.place
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

    # postal => point, or nil when OneMap does not know the code (those students have no stop).
    def locate
      found = Geocode.call(@study)
      n = found[:unreachable].size
      raise Error, "#{n} postal code#{'s' unless n == 1} could not be checked on OneMap. Use Check Again, then run" if n.positive?

      found[:points]
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
        "road" => !!res["road"],
        "summary" => res["summary"].slice("routes", "assigned", "unassigned", "avgJourney", "maxJourney", "avgFill"),
        "routes" => res["routes"].map do |r|
          { "id" => r["id"], "type" => r["type"], "label" => r["label"], "attendant" => !!r["attendant"], "load" => r["load"], "seats" => r["studentSeats"],
            "minutes" => (r["span"].to_f / 60).round, "startT" => r["startT"], "endT" => r["endT"],
            "stops" => r["stops"].map { |z| { "ll" => z["ll"], "n" => z["n"], "time" => z["time"], "name" => z["name"], "postals" => postals_of(z["riders"], postal) } } }
        end,
        "unassigned" => Array(res["unassigned"]).map { it.slice("n", "reason", "label").merge("riders" => Array(it["riders"]).compact) } }
    rescue Routing::Client::Unavailable => e
      raise Error, "The routing service is not available (#{e.message})"
    end

    def postals_of(rids, postal)
      Array(rids).filter_map { postal[it] }.tally.map { |pc, n| n > 1 ? "#{pc} x#{n}" : pc }.join(", ")
    end

    # Company parameters, the scenario's overrides, then what the scenario sets itself. As the prototype (fzPar, fzRun):
    # a changed AM Arrival / PM Dismissal moves its window around it, Seat Buffer replaces every bus size's buffer.
    def params(se)
      mine = @sc.params
      base = (RoutingSetting.first&.params || {}).merge(mine)
      base["amWin"] = window(mine["amTarget"], -5, 10) if mine["amTarget"]
      base["pmWin"] = window(mine["pmTarget"], -15, 0) if mine["pmTarget"]
      types = Array(base["types"].presence || engine_types).map do |t|
        t.merge("on" => @sc.sizes.include?(t["type"])).merge(mine.key?("headroom") ? { "headroom" => mine["headroom"] } : {})
      end
      base.merge("session" => se, "attendant" => @sc.attendant, "attSizes" => [], "hardCap" => @sc.hard_cap, "targetCap" => @sc.target_cap, "types" => types)
    end

    def engine_types
      meta = Routing::Client.current.meta
      meta.dig("defaults", "types").presence || meta["types"]
    end

    def window(target, from, to)
      t = Clock.minutes(target)
      [ Clock.hm([ t + from, 0 ].max), Clock.hm(t + to) ]
    end
  end
end
