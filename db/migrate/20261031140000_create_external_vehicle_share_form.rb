# External Vehicles > Share Form: a public link the hired bus's driver opens to send the bus, their own details and the
# company they drive for. Answers wait (pending) until someone presses Review and Add (added, with the vehicle made)
# or Dismiss. One live link per company; a new link revokes the old one, answers already sent are kept.
class CreateExternalVehicleShareForm < ActiveRecord::Migration[8.1]
  def change
    create_table :external_vehicle_share_links do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :token, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :external_vehicle_share_links, :token, unique: true
    add_index :external_vehicle_share_links, :company_id, unique: true, where: "revoked_at IS NULL", name: "index_external_share_links_one_live"
    add_index :external_vehicle_share_links, :company_id

    create_table :external_vehicle_submissions do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :share_link, null: false, foreign_key: { to_table: :external_vehicle_share_links }
      t.string :plate, null: false
      t.integer :seats
      t.string :driver_name, null: false
      t.string :driver_phone, null: false
      t.string :company_name, null: false
      t.string :company_phone
      t.string :paynow
      t.string :status, null: false, default: "pending"
      t.references :vehicle, foreign_key: true
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at
      t.string :submitted_ip
      t.timestamps
    end
    add_index :external_vehicle_submissions, %i[company_id status created_at]
    add_check_constraint :external_vehicle_submissions, "status IN ('pending', 'added', 'dismissed')", name: "external_vehicle_submissions_status"
  end
end
