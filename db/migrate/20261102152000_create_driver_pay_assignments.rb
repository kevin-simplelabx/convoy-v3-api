# HR > Drivers: the pay scheme and the vehicle type (which rates apply) of a driver over time. Rows of a driver never
# overlap: a new row ends the one before it (ends_on = day before). A driver with no scheme rows is paid on the
# default scheme; with no vehicle type rows, on the type of the bus they drive that day.
class CreateDriverPayAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :driver_pay_schemes do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver, null: false, foreign_key: true, index: false
      t.references :pay_scheme, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on
      t.timestamps
    end
    add_index :driver_pay_schemes, %i[driver_id starts_on], unique: true
    add_index :driver_pay_schemes, :company_id

    create_table :driver_vehicle_types do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver, null: false, foreign_key: true, index: false
      t.references :vehicle_type, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on
      t.timestamps
    end
    add_index :driver_vehicle_types, %i[driver_id starts_on], unique: true
    add_index :driver_vehicle_types, :company_id
  end
end
