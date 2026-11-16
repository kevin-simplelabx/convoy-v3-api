class ValidateAppLinkOnClientUsers < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :client_users, :app_accounts
    validate_check_constraint :client_users, name: "client_users_app_link_status"
  end
end
