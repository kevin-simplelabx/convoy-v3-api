# School Bus › Schools: the school's postal code (placed on the map through OneMap), how its routes are named per
# session (Route Labels), and a shared cache of OneMap postal code lookups (schools, riders, rider files).
class CreateSchoolSetupBasics < ActiveRecord::Migration[8.1]
  def change
    add_column :schools, :postal, :string

    create_table :school_route_labels do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.string :session, null: false
      t.string :prefix, null: false, default: ""
      t.integer :start, null: false, default: 1
      t.integer :digits, null: false, default: 0
      t.string :suffix, null: false, default: ""
      t.timestamps
    end
    add_index :school_route_labels, %i[school_id session], unique: true

    create_table :postal_geocodes do |t|
      t.string :country, null: false, default: "SG"
      t.string :postal, null: false
      t.boolean :found, null: false
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.string :address
      t.timestamptz :looked_up_at, null: false
    end
    add_index :postal_geocodes, %i[country postal], unique: true
  end
end
