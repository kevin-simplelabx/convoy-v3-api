class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :company, null: false, foreign_key: true
      t.string :plate
      t.string :vehicle_type
      t.integer :seats
      t.string :driver_name
      t.string :driver_contact
      t.string :notes
      t.string :operator_id
      t.string :operator_name
      t.string :operator_contact
      t.string :operator_phone
      t.string :tags
      t.text :photo
      t.text :driver_photo
      t.boolean :sample

      t.timestamps
    end
  end
end
