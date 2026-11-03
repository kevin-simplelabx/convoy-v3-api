# A stand-in for the routing service: plans every group, two stops a route (23-seaters), times from 06:30 (AM) or 14:00;
# retime keeps the stops' order and marks the route Edited; down = unreachable; fail = the engine refuses.
class FakeRouting
  attr_reader :inputs
  attr_accessor :down, :fail

  def initialize
    @inputs = []
  end

  def meta = { "defaults" => { "session" => "AM", "effort" => "high", "hardCap" => 75 }, "types" => [], "presets" => {}, "effort" => {}, "max_effort" => "high", "engines" => {} }

  def solve(input)
    raise Routing::Client::Unavailable, "down" if down

    input = input.deep_stringify_keys
    @inputs << input
    return { "status" => "FAILED", "validation" => [ { "level" => "Error", "msg" => "Road travel times could not be loaded" } ] } if fail

    am = input.dig("params", "session") == "AM"
    routes = input["groups"].each_slice(2).with_index.map { |gs, i| route("R%02d" % (i + 1), gs, am ? 390 + (i * 5) : 840) }
    assign = routes.flat_map { |r| r["stops"].flat_map { |s| s["riders"].map { |rid| [ rid, { "uid" => s["uid"], "pid" => s["pid"], "route" => r["id"], "time" => s["time"] } ] } } }.to_h
    { "status" => "COMPLETED", "road" => true, "validation" => [], "routes" => routes, "assign" => assign, "unassigned" => [],
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
      "fill" => load / 23.0, "span" => 2400, "startT" => Clock.hm(start), "endT" => Clock.hm(start + 40), "badges" => load < 12 ? [ "Underfilled" ] : [],
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
