class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :company, null: false, foreign_key: true
      t.string   :code, null: false                 # CL00001
      t.string   :kind, null: false, default: "company" # company | individual | transport_company (main contractor)
      t.string   :name, null: false
      t.string   :uen
      t.string   :contact_name
      t.string   :phone
      t.string   :email
      t.text     :billing_address
      t.integer  :on_time_allowance, null: false, default: 3  # minutes after the timetable that still count as on time
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :clients, %i[company_id code], unique: true
    add_index :clients, %i[company_id name], unique: true, where: "discarded_at IS NULL"
    add_index :clients, :discarded_at

    create_table :client_sites do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :address
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.timestamps
    end
    add_index :client_sites, %i[client_id name], unique: true

    # Their Customers: who a main contractor (transport_company client) serves; Service For on trips.
    create_table :client_end_customers do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.timestamps
    end
    add_index :client_end_customers, %i[client_id name], unique: true

    # Saved pick-up points (gates, bus bays) listed first in the trip form's place search.
    create_table :client_pickup_points do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string  :name, null: false
      t.text    :address
      t.string  :postal_code
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text    :note
      t.timestamps
    end
    add_index :client_pickup_points, %i[client_id name], unique: true
  end
end
