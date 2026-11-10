# Route Again (port of Convoy OS rerouteEngine): the run planned the riders that are not on the plan's locked routes.
# Its routes take the numbers the locked routes leave free (R01, R02 …); an unlocked route with that number is
# updated in place (same id, so its bus, prices, charges and attendant stay), unlocked routes left over go
# (Plans::DropRoute), and new numbers become new routes. Hand edits and hidden flags of unlocked routes go. The run's
# result keeps the locked routes' engine routes too, so Reset Route still finds them. Only a draft plan: an adopted
# plan runs on the Scheduler.
module Plans
  class MergeAgain < ApplicationService
    BLOCKED = "Make a new plan to route again".freeze

    def initialize(run)
      @run = run
      @plan = run.target_plan
    end

    def call
      raise Error, BLOCKED if @plan.in_use

      res = @run.result
      SchoolPlan.transaction do
        @plan.lock!
        routes = @plan.routes.includes(:stops).to_a
        locked = routes.select(&:locked)
        free = free_numbers(locked)
        unlocked = routes.reject(&:locked).index_by(&:number)
        renamed = Array(res["routes"]).map do |er|
          n = free.next
          er = er.merge("id" => format("R%02d", n))
          route = unlocked.delete(n) || @plan.routes.build(number: n)
          route.assign_attributes(label: Plans.label(@plan.school, @plan.session, n), manual: false, edited: false, hidden: false, vias: [])
          Plans.write_route(route, er)
          er
        end
        DropRoute.call(unlocked.values)
        kept = Array(@plan.routing_run&.result&.dig("routes")).select { |er| locked.any? { it.route_key == er["id"] } }
        @run.update!(result: res.merge("routes" => kept + renamed)) # so Reset finds each route by its key
        unassigned = res["unassigned"] || []
        @plan.update!(params: res["params"], unassigned:, routing_run: @run, summary: Plans.summary(@plan.reload, unassigned))
      end
      @plan
    end

    private

    # Numbers the locked routes do not use, by number or by key (a locked R02 numbered 1 keeps 2 out too).
    def free_numbers(locked)
      taken = locked.flat_map { [ it.number, it.route_key.to_s[/\AR(\d+)\z/, 1]&.to_i ] }.compact.to_set
      (1..).lazy.reject { taken.include?(it) }
    end
  end
end
