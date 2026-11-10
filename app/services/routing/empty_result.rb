# The engine's result for an input with no rider at a stop (no groups), made here instead of in the routing service: with
# no stop point there is no road matrix to load and the engine would refuse the run (ROAD_TIMES_UNAVAILABLE). Same keys
# as the engine's solve: no routes, riders with no stop / more than one stop unassigned as the engine labels them, their
# warnings, the summary of no routes, and the engine's parameters (defaults + the run's).
module Routing
  class EmptyResult < ApplicationService
    def initialize(input)
      @input = input.deep_stringify_keys
    end

    def call
      no_stop = Array(@input["noStop"])
      conflicts = Array(@input["conflicts"])
      unassigned = no_stop.map { entry(it, "RIDER_NO_STOP") } + conflicts.map { entry(it, "RIDER_IN_CONFLICT") }
      params = Routing.defaults.merge(@input["params"] || {})
      params["types"] = Routing.types if params["types"].blank? # as the engine: the run's bus types, else its own
      { "status" => unassigned.any? ? "COMPLETED_WITH_UNASSIGNED" : "COMPLETED", "road" => false, "validation" => validation(no_stop, conflicts),
        "routes" => [], "assign" => {}, "unassigned" => unassigned, "summary" => summary(unassigned.size), "params" => params, "ms" => 0,
        "dir" => params["session"] == "AM" ? "pickup" : "dropoff", "obj" => 0 }
    end

    private

    def entry(rider, reason) = { "gid" => nil, "riders" => [ rider["rid"] ], "n" => 1, "reason" => reason, "label" => rider["name"] }

    # The engine's pre-run warnings, word for word.
    def validation(no_stop, conflicts)
      v = []
      v << { "code" => "RIDER_NO_STOP", "level" => "Warning", "msg" => "#{no_stop.size} #{no_stop.one? ? 'rider has' : 'riders have'} no stop. Excluded from this run" } if no_stop.any?
      v << { "code" => "RIDER_IN_CONFLICT", "level" => "Warning", "msg" => "#{conflicts.size} #{conflicts.one? ? 'rider is' : 'riders are'} covered by more than one stop. Excluded until resolved" } if conflicts.any?
      v
    end

    def summary(left)
      { "riders" => left, "assigned" => 0, "unassigned" => left, "routes" => 0, "byType" => {}, "avgJourney" => 0, "maxJourney" => 0, "avgFill" => 0,
        "fixed" => 0, "run" => 0, "overtime" => 0, "floor" => 0, "stability" => 0, "slots" => {}, "total" => 0 }
    end
  end
end
