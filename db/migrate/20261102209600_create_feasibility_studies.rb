# School Bus › Feasibility Studies (company sandbox, nothing touches real riders or stops): a school (existing, or a
# prospect placed by its postal code), students by postal code × count × session, door-to-door or library PUDOs within a
# walk, monthly bus prices with attendant add-on, fare tiers; scenarios (bus sizes, attendants, ride limits, margin,
# buffer buses, parameter overrides) each planned by the routing engine (AM and PM), the result kept as a snapshot.
class CreateFeasibilityStudies < ActiveRecord::Migration[8.1]
  def change
    create_table :feasibility_studies do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :school_mode, null: false, default: "prospect"
      t.references :school, foreign_key: true, index: false
      t.string :prospect_name
      t.string :prospect_postal
      t.decimal :prospect_lat, precision: 10, scale: 7
      t.decimal :prospect_lng, precision: 10, scale: 7
      t.string :pickup, null: false, default: "door"
      t.integer :walk_m, null: false, default: 400
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :feasibility_studies, %i[company_id updated_at]

    create_table :feasibility_rows do |t|
      t.references :feasibility_study, null: false, foreign_key: { on_delete: :cascade }
      t.string :postal, null: false
      t.integer :riders, null: false, default: 1
      t.string :session, null: false, default: "both"
      t.string :level
    end

    create_table :feasibility_bus_prices do |t|
      t.references :feasibility_study, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :bus_type, null: false
      t.decimal :monthly, precision: 12, scale: 2
      t.decimal :attendant, precision: 12, scale: 2
    end
    add_index :feasibility_bus_prices, %i[feasibility_study_id bus_type], unique: true

    create_table :feasibility_fare_tiers do |t|
      t.references :feasibility_study, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.decimal :max_km, precision: 6, scale: 2
      t.decimal :fare, precision: 12, scale: 2
      t.decimal :one_way_fare, precision: 12, scale: 2
    end
    add_index :feasibility_fare_tiers, %i[feasibility_study_id position]

    create_table :feasibility_scenarios do |t|
      t.references :feasibility_study, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.string :name, null: false
      t.string :sizes, array: true, null: false, default: []
      t.string :attendant, null: false, default: "STATUTORY"
      t.integer :hard_cap, null: false, default: 75
      t.integer :target_cap, null: false, default: 50
      t.decimal :margin_pct, precision: 5, scale: 2, null: false, default: 30
      t.jsonb :extra_buses, null: false, default: {}
      t.jsonb :params, null: false, default: {}
      t.string :status, null: false, default: "idle"
      t.jsonb :result
      t.boolean :stale, null: false, default: false
      t.text :error
      t.timestamps
    end
  end
end
