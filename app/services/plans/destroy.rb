# Delete a draft plan with its routes and all that hangs on them (Plans::DropRoute; a route whose runs are history stays).
module Plans
  class Destroy < ApplicationService
    def initialize(plan)
      @plan = plan
    end

    def call
      raise Error, "Only a draft plan can be deleted" unless @plan.state == "draft"

      SchoolPlan.transaction do
        DropRoute.call(@plan.routes.to_a)
        @plan.reload.destroy!
      end
    end
  end
end
