# Convoy App Phase 3: a teacher's booking link. When a verified work email equals a client user's email, the user is
# offered to that app account (status invited); Accept / Not Me answers it. Removing the client user ends the link.
class AddAppLinkToClientUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :client_users, :app_account_id, :bigint
    add_column :client_users, :app_link_status, :string
    add_column :client_users, :app_matched_email, :string
    add_column :client_users, :app_link_responded_at, :datetime
    add_index :client_users, :app_account_id, algorithm: :concurrently
    add_index :client_users, %i[client_id app_account_id], unique: true, where: "app_account_id IS NOT NULL AND discarded_at IS NULL",
                                                           name: "index_client_users_one_app_link", algorithm: :concurrently
    add_foreign_key :client_users, :app_accounts, column: :app_account_id, on_delete: :nullify, validate: false
    add_check_constraint :client_users, "app_link_status IN ('invited', 'accepted', 'declined')", name: "client_users_app_link_status", validate: false
  end
end
