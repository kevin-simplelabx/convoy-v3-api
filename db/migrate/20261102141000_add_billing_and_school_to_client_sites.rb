# Managed Clients > Edit Site: the site's own School Bus school (one site or client per school), and billing as its
# own legal entity (legal name, UEN, address; who gets the invoices is client_billing_contacts). Who added the site and
# the saved pick-up points ("Added by X on date").
class AddBillingAndSchoolToClientSites < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :client_sites, :school, index: { unique: true, where: "school_id IS NOT NULL", algorithm: :concurrently }
    add_foreign_key :client_sites, :schools, validate: false
    add_column :client_sites, :own_billing, :boolean, null: false, default: false
    add_column :client_sites, :billing_name, :string
    add_column :client_sites, :billing_uen, :string
    add_column :client_sites, :billing_address, :text
    add_reference :client_sites, :created_by, index: { algorithm: :concurrently }
    add_foreign_key :client_sites, :users, column: :created_by_id, validate: false

    add_reference :client_pickup_points, :created_by, index: { algorithm: :concurrently }
    add_foreign_key :client_pickup_points, :users, column: :created_by_id, validate: false
  end
end
