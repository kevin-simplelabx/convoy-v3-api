# Fleet > Fuel & Energy: every refuel (diesel, petrol, AdBlue) and charge (electricity) of own vehicles, with the
# odometer, the driver of the day and the receipt. Columns after "derived" are worked out by FuelEntries::Recompute for
# the whole vehicle history whenever an entry changes, so lists and statistics read them directly:
#   km_since     km since the vehicle's previous reading (null when the odometer went back)
#   efficiency   km/L (diesel, petrol) or kWh/100km (electricity), measured full fill to full fill of the same energy
#   odometer_back  the higher reading before this one, when the odometer went back
class CreateFuel < ActiveRecord::Migration[8.1]
  def change
    # Fuel and charging companies picked on each entry (Esso, Shell, SP Mobility...), per company.
    create_table :fuel_companies do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :kind, null: false, default: "fuel"
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :fuel_companies, "company_id, LOWER(name)", unique: true, name: "index_fuel_companies_on_company_and_name"
    add_check_constraint :fuel_companies, "kind IN ('fuel', 'elec', 'both')", name: "fuel_companies_kind"

    create_table :fuel_entries do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :vehicle, null: false, foreign_key: true, index: false
      t.references :driver, foreign_key: true
      t.date :date, null: false
      t.integer :time
      t.string :kind, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.decimal :cost, precision: 12, scale: 2, null: false
      t.integer :odometer
      t.boolean :full, null: false, default: true
      t.references :fuel_company, foreign_key: true
      t.string :station
      t.text :note
      t.string :receipt
      t.references :document_read, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      # derived
      t.integer :km_since
      t.decimal :efficiency, precision: 7, scale: 1
      t.integer :odometer_back
      t.timestamps
    end
    add_index :fuel_entries, %i[company_id date]
    add_index :fuel_entries, %i[vehicle_id date]
    add_check_constraint :fuel_entries, "kind IN ('diesel', 'petrol', 'def', 'elec')", name: "fuel_entries_kind"
    add_check_constraint :fuel_entries, "quantity > 0 AND cost >= 0", name: "fuel_entries_amounts"
  end
end
