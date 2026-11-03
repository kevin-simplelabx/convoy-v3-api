# Delete a draft plan with its routes, stops and riders in a few statements (a draft has no runs on the Scheduler).
module Plans
  class Destroy < ApplicationService
    def initialize(plan)
      @plan = plan
    end

    def call
      raise Error, "Only a draft plan can be deleted" unless @plan.state == "draft"

      SchoolPlan.transaction do
        ids = @plan.routes.pluck(:id)
        [ SchoolRouteRider, SchoolRouteStop, SchoolRouteVehicleChange, SchoolRouteReplacement ].each { it.where(school_route_id: ids).delete_all }
        SchoolRoute.where(id: ids).delete_all
        @plan.reload.destroy!
      end
    end
  end
end
