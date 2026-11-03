# Validate the foreign keys added to existing tables by CreateRouting (added without validation, strong_migrations).
class ValidateRoutingForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :school_plans, :routing_runs
    validate_foreign_key :school_plans, column: :adopted_by_id
    validate_foreign_key :school_plans, column: :created_by_id
    validate_foreign_key :school_route_stops, :stops
    validate_foreign_key :school_route_stops, :stop_points
  end
end
