# Convoy App Phase 3: the work-email domains of a Managed Client ("google.com"). A verified work email on one of them
# invites the person to the client's staff shuttle (client_riders). Optional: [] = nobody is found by domain.
class AddEmailDomainsToClients < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :clients, :email_domains, :string, array: true, default: [], null: false
    add_index :clients, :email_domains, using: :gin, algorithm: :concurrently
  end
end
