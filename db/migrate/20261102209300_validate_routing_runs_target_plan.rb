# Validate the foreign key added by AddRouteAgainToRoutingRuns (strong_migrations).
class ValidateRoutingRunsTargetPlan < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :routing_runs, column: :target_plan_id
  end
end
