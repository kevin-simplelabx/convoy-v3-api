class ValidateSchoolRouteKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :replacements, :school_routes
    validate_foreign_key :notices, :schools
    validate_check_constraint :replacements, name: "replacements_run_source"
    validate_check_constraint :replacements, name: "replacements_range_kinds"
  end
end
