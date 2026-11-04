# Validates the pay_to_operator key of the previous migration.
class ValidateSchoolRoutesPayToOperator < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :school_routes, column: :pay_to_operator_id
  end
end
