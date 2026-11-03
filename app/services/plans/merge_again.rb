# Route Again: the run planned the riders that are not on the plan's locked routes; its routes replace the unlocked
# routes (numbered after the locked ones), and its unassigned riders become the plan's.
module Plans
  class MergeAgain < ApplicationService
    def initialize(run)
      @run = run
      @plan = run.target_plan
    end

    def call
      res = @run.result
      SchoolPlan.transaction do
        gone = @plan.routes.where(locked: false).pluck(:id)
        [ SchoolRouteRider, SchoolRouteStop, SchoolRouteVehicleChange, SchoolRouteReplacement ].each { it.where(school_route_id: gone).delete_all }
        SchoolRoute.where(id: gone).delete_all
        taken = @plan.routes.reload.pluck(:number)
        free = (1..).lazy.reject { taken.include?(it) }
        renamed = Array(res["routes"]).zip(free.first(Array(res["routes"]).size)).map do |er, n|
          er = er.merge("id" => format("R%02d", n))
          Plans.write_route(@plan.routes.build(number: n, label: Plans.label(@plan.school, @plan.session, n)), er)
          er
        end
        @run.update!(result: res.merge("routes" => renamed)) # so Reset finds each route by its number
        @plan.update!(params: res["params"], unassigned: res["unassigned"] || [], routing_run: @run, summary: Plans.summary(@plan.reload, res["unassigned"] || []))
        AcademicYears.resync(@plan.school) if @plan.in_use
      end
      @plan
    end
  end
end
