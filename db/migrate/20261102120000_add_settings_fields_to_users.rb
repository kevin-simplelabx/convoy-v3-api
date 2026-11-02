# Settings > Users: soft delete (a deleted user's name stays on past records; the email can be used again for a new
# user, so it is unique only among users not deleted), school access (all schools, including new ones, or the schools
# in user_schools), who added the user, and the Profile's display name.
class AddSettingsFieldsToUsers < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :users, :discarded_at, :datetime
    add_column :users, :all_schools, :boolean, null: false, default: true
    add_column :users, :display_name, :string
    add_reference :users, :created_by, index: { algorithm: :concurrently }
    add_foreign_key :users, :users, column: :created_by_id, validate: false

    remove_index :users, :email, unique: true, algorithm: :concurrently
    add_index :users, :email, unique: true, algorithm: :concurrently, where: "discarded_at IS NULL", name: "index_users_on_live_email"
    add_index :users, %i[company_id discarded_at], algorithm: :concurrently
  end
end
