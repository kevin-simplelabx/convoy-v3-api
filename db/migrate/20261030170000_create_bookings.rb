# Trips > Bookings: a client's request for trips over up to 10 days. Each booking trip is approved on its own (Phase 5
# turns it into Scheduler trips). Rows (not JSON) so bookings can be searched, counted and reported on; only the
# estimate breakdown at save time is kept as a jsonb snapshot.
class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :company, null: false, foreign_key: true
      t.string :number, null: false
      t.references :client, null: false, foreign_key: true
      t.references :client_site, foreign_key: true
      t.references :client_end_customer, foreign_key: true
      t.string :service_for
      t.string :coordinator_name, null: false
      t.string :coordinator_org
      t.string :coordinator_email
      t.string :coordinator_phone
      t.string :po_number
      t.string :cost_centre
      t.text :notes
      t.string :source, null: false, default: "console"
      t.references :created_by, foreign_key: { to_table: :users }
      t.decimal :estimate_amount, precision: 12, scale: 2, null: false, default: 0
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_index :bookings, %i[company_id number], unique: true
    add_index :bookings, %i[company_id created_at]

    create_table :booking_days do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.date :date, null: false
      t.timestamps
    end
    add_index :booking_days, %i[booking_id date], unique: true
    add_index :booking_days, %i[company_id date]

    create_table :booking_trips do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.references :booking_day, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.string :label
      t.integer :start_time, null: false
      t.integer :return_time
      t.decimal :hours, precision: 5, scale: 2
      t.string :airport_direction
      t.string :flight_number
      t.string :terminal
      t.integer :wait_minutes
      t.boolean :meet_and_greet, null: false, default: false
      t.string :signboard_name
      t.integer :pax, null: false, default: 0
      t.boolean :luggage_on, null: false, default: false
      t.integer :luggage_cabin, null: false, default: 0
      t.integer :luggage_medium, null: false, default: 0
      t.integer :luggage_large, null: false, default: 0
      t.integer :luggage_extra_large, null: false, default: 0
      t.integer :luggage_oversized, null: false, default: 0
      t.string :contact_name
      t.string :contact_phone
      t.text :note
      t.decimal :distance_km, precision: 8, scale: 1
      t.decimal :return_distance_km, precision: 8, scale: 1
      t.decimal :estimate_amount, precision: 12, scale: 2, null: false, default: 0
      t.jsonb :estimate_lines, null: false, default: []
      t.timestamps
    end
    add_index :booking_trips, %i[company_id status]

    create_table :booking_trip_points do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking_trip, null: false, foreign_key: true, index: false
      t.string :leg, null: false, default: "out"
      t.integer :position, null: false
      t.string :name, null: false
      t.string :address
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.string :use, null: false, default: "both"
      t.text :note
      t.timestamps
    end
    add_index :booking_trip_points, %i[booking_trip_id leg position], unique: true

    create_table :booking_trip_standbys do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking_trip, null: false, foreign_key: true, index: false
      t.string :leg, null: false, default: "out"
      t.string :location, null: false
      t.integer :minutes, null: false, default: 10
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text :note
      t.timestamps
    end
    add_index :booking_trip_standbys, %i[booking_trip_id leg], unique: true

    create_table :booking_trip_vehicles do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking_trip, null: false, foreign_key: true, index: false
      t.references :vehicle_type, null: false, foreign_key: true
      t.integer :count, null: false, default: 1
      t.timestamps
    end
    add_index :booking_trip_vehicles, %i[booking_trip_id vehicle_type_id], unique: true

    create_table :booking_attachments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.string :file, null: false
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
