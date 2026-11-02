# Bookable Vehicles: the vehicle types a client can pick in the Client Portal booking form. None = every type offered.
class CreateClientBookableVehicleTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :client_bookable_vehicle_types do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :client, null: false, foreign_key: true, index: false
      t.references :vehicle_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :client_bookable_vehicle_types, %i[client_id vehicle_type_id], unique: true
    add_index :client_bookable_vehicle_types, :company_id
  end
end
