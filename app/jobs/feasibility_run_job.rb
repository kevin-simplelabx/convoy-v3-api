# Plans one feasibility scenario in the routing service (Feasibility::Run) and keeps the result or why it failed.
class FeasibilityRunJob < ApplicationJob
  queue_as :default

  def perform(scenario_id)
    sc = FeasibilityScenario.find_by(id: scenario_id) or return
    company = sc.feasibility_study.company
    ActsAsTenant.with_tenant(company) do
      result = Feasibility::Run.call(sc)
      sc.update!(status: "done", result:, stale: false, error: nil, ran_at: Time.current)
    rescue ApplicationService::Error => e
      sc.update!(status: "failed", error: e.message)
    end
  end
end
