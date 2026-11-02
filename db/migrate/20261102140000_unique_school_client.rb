# Managed Clients > This Client Is a School: a school is linked to at most one client.
class UniqueSchoolClient < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    remove_index :schools, :client_id, algorithm: :concurrently
    add_index :schools, :client_id, unique: true, where: "client_id IS NOT NULL", algorithm: :concurrently
  end
end
