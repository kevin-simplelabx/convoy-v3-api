# A stand-in for the routing service: plans every group, two stops a route (23-seaters), times from 06:30 (AM) or 14:00;
# retime keeps the stops' order and marks the route Edited; riders with no stop or in conflict come back unassigned (as
# the engine labels them); no groups = no road times, refused as the real engine does (RoutingRunJob must not send it);
# down = unreachable; fail = the engine refuses.
class FakeRouting
  attr_reader :inputs
  attr_accessor :down, :fail

  def initialize
    @inputs = []
  end

  def meta = { "defaults" => { "session" => "AM", "effort" => "high", "hardCap" => 75 }, "types" => [], "presets" => {}, "effort" => {}, "max_effort" => "high", "engines" => {} }

  def progress(_key) = { "step" => "solving", "frac" => 0.5, "run" => 1, "runs" => 2, "work" => { "phase" => "Swap and relocate pass", "i" => 3, "n" => 9, "evals" => 1200 } }

  def solve(input, key: nil)
    raise Routing::Client::Unavailable, "down" if down

    input = input.deep_stringify_keys
    @inputs << input
    return { "status" => "FAILED", "validation" => [ { "level" => "Error", "msg" => "Road travel times could not be loaded" } ] } if fail || input["groups"].empty?

    am = input.dig("params", "session") == "AM"
    routes = input["groups"].each_slice(2).with_index.map { |gs, i| route("R%02d" % (i + 1), gs, am ? 390 + (i * 5) : 840) }
    assign = routes.flat_map { |r| r["stops"].flat_map { |s| s["riders"].map { |rid| [ rid, { "uid" => s["uid"], "pid" => s["pid"], "route" => r["id"], "time" => s["time"] } ] } } }.to_h
    unassigned = Array(input["noStop"]).map { { "gid" => nil, "riders" => [ it["rid"] ], "n" => 1, "reason" => "RIDER_NO_STOP", "label" => it["name"] } } +
                 Array(input["conflicts"]).map { { "gid" => nil, "riders" => [ it["rid"] ], "n" => 1, "reason" => "RIDER_IN_CONFLICT", "label" => it["name"] } }
    { "status" => "COMPLETED", "road" => true, "validation" => [], "routes" => routes, "assign" => assign, "unassigned" => unassigned,
      "summary" => { "riders" => assign.size, "assigned" => assign.size, "unassigned" => 0, "routes" => routes.size, "byType" => { "MEDIUM_23" => routes.size },
                     "avgJourney" => 40.0, "maxJourney" => 45.0, "avgFill" => 0.5, "total" => 100.0 },
      "params" => input["params"].merge("preset" => input.dig("params", "preset") || "FEWEST_BUSES"), "ms" => 1200 }
  end

  def retime(payload)
    raise Routing::Client::Unavailable, "down" if down

    p = payload.deep_stringify_keys
    stops = p["stops"].each_with_index.map { |s, i| s.merge("time" => Clock.hm(390 + (i * 10))) }
    sized = p["type"] ? { "type" => p["type"], "seats" => p["type"] == "SMALL_13" ? 13 : 23 } : {}
    p["base"].merge(sized).merge("stops" => stops, "load" => stops.sum { it["n"].to_i }, "badges" => [ "Edited" ], "startT" => "06:30",
                                 "endT" => Clock.hm(400 + (stops.size * 10)), "span" => 600 + (stops.size * 600))
  end

  # Best order (stand-in): stops by point id; routes already in that order are left out.
  def optimise(payload)
    raise Routing::Client::Unavailable, "down" if down

    p = payload.deep_stringify_keys
    { "routes" => p["routes"].filter_map do |r|
      order = r["stops"].each_with_index.sort_by { |s, _| s["pid"].to_i }.map(&:last)
      next if order == (0...r["stops"].size).to_a

      { "id" => r["id"], "order" => order, "before" => { "span" => 1800, "ride" => 300 }, "after" => { "span" => 1500, "ride" => 240 } }
    end }
  end

  def diff(a, b) = { "routes" => [ a["routes"].size, b["routes"].size ], "moved" => 0 }

  private

  def route(id, groups, start)
    stops = groups.each_with_index.map do |g, k|
      pt = g["points"].first
      { "uid" => g["uid"], "stopId" => g["stopId"], "name" => g["name"], "pid" => pt["pid"], "sfx" => pt["sfx"], "ll" => [ pt["lat"], pt["lng"] ],
        "n" => g["riders"].size, "riders" => g["riders"], "time" => Clock.hm(start + (k * 10)), "dwell" => 60 }
    end
    load = stops.sum { it["n"] }
    { "id" => id, "type" => "MEDIUM_23", "label" => "23-seater", "cls" => "M", "seats" => 23, "studentSeats" => 23, "cap" => 20, "floor" => 12, "load" => load,
      "fill" => load / 23.0, "span" => 2400, "start" => start * 60, "end" => (start + 40) * 60, "startT" => Clock.hm(start), "endT" => Clock.hm(start + 40),
      "badges" => load < 12 ? [ "Underfilled" ] : [], "cost" => { "fixed" => 480, "run" => 20.0, "ride" => 1.5, "overtime" => 0.0, "floor" => 0, "stability" => 0 },
      "rideMin" => load * 20, "stops" => stops }
  end
end

module FakeRoutingHelper
  def fake_routing = @fake_routing ||= FakeRouting.new
end

RSpec.configure do |config|
  config.include FakeRoutingHelper
  config.before { Routing::Client.current = fake_routing }
  config.after { Routing::Client.current = nil }
end
