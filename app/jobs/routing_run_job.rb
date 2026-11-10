# Runs one routing run in the routing service and makes its draft plan (Plans::FromResult), or for Route Again replaces
# the plan's unlocked routes (Plans::MergeAgain). A run with no rider at a stop skips the engine: done with an empty
# plan, every rider unassigned (Routing::EmptyResult). A run the engine could not plan (validation errors, no road times), the
# service could not finish, or whose plan was adopted meanwhile (Route Again) is failed with the reason.
class RoutingRunJob < ApplicationJob
  queue_as :default

  def perform(run_id)
    run = RoutingRun.unscoped.find_by(id: run_id) or return
    ActsAsTenant.with_tenant(run.company) do
      Time.use_zone(run.company.timezone) do
        run.update!(status: "running", started_at: Time.current)
        result = solve(run)
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
  rescue ApplicationService::Error => e
    run&.update_columns(status: "failed", error: e.message, finished_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  # No rider at a stop: nothing to route and no road times to load (the engine would refuse), so the run is done here
  # with no routes and every rider unassigned (Routing::EmptyResult).
  def solve(run)
    return Routing::EmptyResult.call(run.input) if Array(run.input["groups"]).empty?

    Routing::Client.current.solve(run.input, key: RoutingRun.progress_key(run.id))
  end
end
