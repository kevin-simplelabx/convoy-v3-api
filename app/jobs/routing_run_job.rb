# Runs one routing run in the routing service and makes its draft plan (Plans::FromResult), or for Route Again replaces
# the plan's unlocked routes (Plans::MergeAgain). A run the engine could not
# plan (validation errors, no road times) or the service could not finish is failed with the reason.
class RoutingRunJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = RoutingRun.unscoped.find_by(id: run_id) or return
    ActsAsTenant.with_tenant(run.company) do
      Time.use_zone(run.company.timezone) do
        run.update!(status: "running", started_at: Time.current)
        result = Routing::Client.current.solve(run.input, key: RoutingRun.progress_key(run.id))
        if result["status"] == "FAILED"
          errors = Array(result["validation"]).select { it["level"] == "Error" }.map { it["msg"] }
          next run.update!(status: "failed", result:, error: errors.join(". ").presence || "The engine could not plan these riders", finished_at: Time.current)
        end
        run.update!(result:, ms: result["ms"])
        run.kind == "again" ? Plans::MergeAgain.call(run) : Plans::FromResult.call(run)
        run.update!(status: "done", finished_at: Time.current)
      end
    end
  rescue Routing::Client::Unavailable => e
    run&.update_columns(status: "failed", error: "The routing service is not available: #{e.message}", finished_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
