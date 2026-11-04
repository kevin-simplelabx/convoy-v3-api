# Client Portal › Settings: teams of a client's portal users (each with an optional manager, for the Their Manager
# approval step), and the client's logo, colour and billing (legal) name.
class CreateClientTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :client_teams do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :client, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :name, null: false
      t.bigint :manager_id
      t.timestamps
    end
    add_index :client_teams, "client_id, lower(name)", unique: true, name: "index_client_teams_on_client_and_name"
    add_index :client_teams, :manager_id

    # Billing name: the legal name on invoices (blank = the client's name). Brand: the client strip in the portal.
    add_column :clients, :billing_name, :string
    add_column :clients, :brand_logo, :string
    add_column :clients, :brand_logo_ratio, :decimal, precision: 5, scale: 2
    add_column :clients, :brand_color, :string
  end
end
