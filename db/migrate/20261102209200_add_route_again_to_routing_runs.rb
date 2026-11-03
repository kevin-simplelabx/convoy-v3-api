# Route Again: a routing run for the riders of a plan that are not on its locked routes; the result replaces the plan's
# unlocked routes (target_plan) instead of making a new plan.
class AddRouteAgainToRoutingRuns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :routing_runs, :kind, :string, null: false, default: "new"
    add_reference :routing_runs, :target_plan, index: { algorithm: :concurrently },
                                               foreign_key: { to_table: :school_plans, on_delete: :cascade, validate: false }
  end
end
