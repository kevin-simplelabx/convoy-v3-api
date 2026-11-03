# A routing run's result as a draft plan: its routes (named by the school's Route Labels), stops and riders, with the
# engine's summary, unassigned riders (with reasons) and parameters.
module Plans
  class FromResult < ApplicationService
    def initialize(run)
      @run = run
    end

    def call
      res = @run.result
      school = @run.school
      SchoolPlan.transaction do
        plan = school.plans.create!(
          name: Plans.next_name(school, @run.session), session: @run.session, effective_from: @run.plan_date, in_use: false, source: "engine",
          routing_run: @run, priority: res.dig("params", "preset"), params: res["params"], summary: res["summary"], unassigned: res["unassigned"] || [],
          created_by: @run.created_by
        )
        Array(res["routes"]).each.with_index(1) do |er, n|
          Plans.write_route(plan.routes.build(number: n, label: Plans.label(school, @run.session, n)), er)
        end
        plan
      end
    end
  end
end
