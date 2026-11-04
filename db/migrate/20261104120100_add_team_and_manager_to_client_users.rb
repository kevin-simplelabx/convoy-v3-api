# A client user's team and own manager (else the team's manager is theirs), and who added them in the portal
# (created_by is a Convoy OS user; a client user adding someone fills created_by_client_user).
class AddTeamAndManagerToClientUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :client_users, :client_team, index: { algorithm: :concurrently }
    add_reference :client_users, :manager, index: { algorithm: :concurrently }
    add_reference :client_users, :created_by_client_user, index: { algorithm: :concurrently }
    add_foreign_key :client_users, :client_teams, on_delete: :nullify, validate: false
    add_foreign_key :client_users, :client_users, column: :manager_id, on_delete: :nullify, validate: false
    add_foreign_key :client_users, :client_users, column: :created_by_client_user_id, on_delete: :nullify, validate: false
    add_foreign_key :client_teams, :client_users, column: :manager_id, on_delete: :nullify, validate: false
  end
end
