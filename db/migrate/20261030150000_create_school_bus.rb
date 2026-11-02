class CreateSchoolBus < ActiveRecord::Migration[8.1]
  def change
    # School Bus (only what the Scheduler shows and changes): schools, their route plans and routes, the regular bus of
    # each route over time, and short replacements. Plans themselves are made in School Bus (routing engine, not built).
    create_table :schools do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, foreign_key: true                 # when the school is also a Managed Client
      t.references :calendar, foreign_key: true               # its school calendar (holidays, No School, early / late days)
      t.string  :name, null: false
      t.string  :short_name
      t.text    :address
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.timestamps
    end
    add_index :schools, %i[company_id name], unique: true

    create_table :school_plans do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :session, null: false                         # am | pm | asa (CCA)
      t.integer :days, array: true, null: false, default: [ 1, 2, 3, 4, 5 ]
      t.date    :effective_from, null: false
      t.date    :effective_to
      t.boolean :in_use, null: false, default: true
      t.timestamps
    end

    create_table :school_routes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school_plan, null: false, foreign_key: true
      t.integer :number, null: false
      t.string  :label, null: false                           # AM 3
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.integer :riders_count, null: false, default: 0
      t.references :attendant, foreign_key: true
      t.timestamps
    end
    add_index :school_routes, %i[school_plan_id number], unique: true

    create_table :school_route_stops do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school_route, null: false, foreign_key: true
      t.integer :position, null: false
      t.string  :name, null: false
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.integer :scheduled_time
      t.integer :riders_count, null: false, default: 0
      t.timestamps
    end

    # The regular bus of a route from a date (vehicle empty = no regular bus from then).
    create_table :school_route_vehicle_changes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school_route, null: false, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.date :effective_from, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :school_route_vehicle_changes, %i[school_route_id effective_from], unique: true, name: "index_route_vehicle_changes_once"

    # A replacement bus on a route for a day or a few (Just This Trip, Replacement for a Date Range).
    create_table :school_route_replacements do |t|
      t.references :company, null: false, foreign_key: true
      t.references :school_route, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.date    :starts_on, null: false
      t.date    :ends_on, null: false
      t.string  :arranged_by, null: false, default: "operator"   # operator (route pay unchanged) | us (we pay the new bus)
      t.decimal :daily_rate, precision: 12, scale: 2
      t.boolean :deduct_from_operator, null: false, default: true
      t.text    :reason
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :school_route_replacements, %i[school_route_id starts_on ends_on], name: "index_route_replacements_dates"

    # Notices for school routes (notices.school_id is added in the next migrations).
    create_table :notice_routes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :notice, null: false, foreign_key: true
      t.references :school_route, null: false, foreign_key: true
      t.timestamps
    end
  end
end
