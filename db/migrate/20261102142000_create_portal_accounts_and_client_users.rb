# Client Portal people. A portal account is one person (one email) who signs in to the Client Portal; it sets its own
# password at first sign-in. A client user is that person at one client of one transport company, with a role and the
# sites they act for (client_user_sites; organisation-wide roles have none). The same email can be a user of several clients.
class CreatePortalAccountsAndClientUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :portal_accounts do |t|
      t.string :email, null: false
      t.string :name
      t.string :encrypted_password, null: false, default: ""
      t.datetime :password_set_at
      t.datetime :last_sign_in_at
      t.timestamps
    end
    add_index :portal_accounts, :email, unique: true

    create_table :client_users do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :client, null: false, foreign_key: true, index: false
      t.references :portal_account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :title
      t.string :email, null: false
      t.string :role, null: false, default: "member"
      t.references :created_by, foreign_key: { to_table: :users }
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :client_users, %i[client_id email], unique: true, where: "discarded_at IS NULL"
    add_index :client_users, %i[company_id client_id]
    add_index :client_users, :email
    add_check_constraint :client_users, "role IN ('super', 'adm', 'fin', 'ssa', 'sa', 'sfin', 'member')", name: "client_users_role"

    create_table :client_user_sites do |t|
      t.references :client_user, null: false, foreign_key: true, index: false
      t.references :client_site, null: false, foreign_key: true
      t.timestamps
    end
    add_index :client_user_sites, %i[client_user_id client_site_id], unique: true
  end
end
