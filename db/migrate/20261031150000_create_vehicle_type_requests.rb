# Vehicle Types > Request a New Type: a company asks Convoy for a type (name, seats, why); a Convoy Admin adds it
# (the new platform type is linked) or declines. Types added this way, or by hand, are custom: only those can be removed.
class CreateVehicleTypeRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_type_requests do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.integer :seats, null: false
      t.text :reason
      t.string :status, null: false, default: "pending"
      t.references :requested_by, foreign_key: { to_table: :users }
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at
      t.references :vehicle_type, foreign_key: true
      t.timestamps
    end
    add_index :vehicle_type_requests, %i[company_id created_at]
    add_index :vehicle_type_requests, %i[status created_at]
    add_check_constraint :vehicle_type_requests, "status IN ('pending', 'added', 'declined')", name: "vehicle_type_requests_status"

    add_column :vehicle_types, :custom, :boolean, null: false, default: false
  end
end
