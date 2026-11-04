class ValidateClientTeamForeignKeys < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :client_users, :client_teams
    validate_foreign_key :client_users, column: :manager_id
    validate_foreign_key :client_users, column: :created_by_client_user_id
    validate_foreign_key :client_teams, column: :manager_id
  end
end
