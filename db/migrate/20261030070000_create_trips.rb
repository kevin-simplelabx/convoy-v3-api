class CreateTrips < ActiveRecord::Migration[8.1]
  def change
    # A trip template: one-off or recurring. Each run on a date (and vehicle) is an occurrence (Phase 4).
    # Times are minutes after midnight; end_time may pass 1440 for a trip past midnight.
    create_table :trips do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :client_site, foreign_key: true
      t.string  :kind, null: false                  # ad_hoc | corporate_shuttle | airport_transfer | disposal | school_run
      t.string  :title, null: false
      t.string  :label

      # Trip ID: TID + trip_no, advancing one per day from trip_no_from for recurring trips (block of trip_no_count numbers).
      t.bigint  :trip_no, null: false
      t.date    :trip_no_from, null: false
      t.integer :trip_no_count, null: false, default: 1

      # When
      t.date    :starts_on, null: false
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.decimal :hours, precision: 5, scale: 2          # Disposal: hours the bus is needed
      t.integer :days, array: true, null: false, default: []   # weekdays for recurring trips, 0 = Sunday; empty = one-off
      t.string  :end_mode, null: false, default: "none"        # none (one-off) | never | date | count
      t.date    :ends_on                                       # last date (end_mode date / count)
      t.integer :occurrence_count                              # end_mode count
      t.boolean :skip_public_holidays, null: false, default: true
      t.references :calendar, foreign_key: true

      # Who and what
      t.integer :pax, null: false, default: 0
      t.boolean :luggage_on, null: false, default: false
      t.integer :luggage_cabin, null: false, default: 0
      t.integer :luggage_medium, null: false, default: 0
      t.integer :luggage_large, null: false, default: 0
      t.integer :luggage_extra_large, null: false, default: 0
      t.integer :luggage_oversized, null: false, default: 0
      t.integer :vehicles_count, null: false, default: 1
      t.string  :requestor_name
      t.string  :requestor_email
      t.string  :requestor_phone
      t.boolean :guest_is_requestor, null: false, default: true
      t.string  :guest_name
      t.string  :guest_phone
      t.text    :notes
      t.string  :business_unit
      t.string  :project
      t.string  :booking_ref                                   # booking the trip came from (Bookings module not built)

      # Airport Transfer
      t.string  :airport_direction                             # arrival | departure
      t.string  :flight_number
      t.integer :flight_time
      t.string  :terminal
      t.integer :wait_minutes, null: false, default: 0         # arrivals: wait after landing
      t.boolean :meet_and_greet, null: false, default: false
      t.string  :signboard_name
      t.decimal :meet_and_greet_fee, precision: 12, scale: 2, null: false, default: 0

      # Revenue (client price) and cost
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0
      t.string  :price_per, null: false, default: "route"      # route (whole route, shared over vehicles) | vehicle
      t.string  :price_set, null: false, default: "same"       # same | each (per vehicle slot)
      t.string  :price_basis, null: false, default: "trip"     # trip | day | month (recurring)
      t.boolean :hourly_rate, null: false, default: false      # Disposal: price is per hour
      t.decimal :trip_value, precision: 10, scale: 2, null: false, default: 1 # own driver's trip value
      t.string  :trip_value_mode, null: false, default: "trips"  # trips | hours
      t.string  :trip_value_rounding, null: false, default: "up" # up | down
      t.decimal :operator_cost, precision: 12, scale: 2         # contractor bus cost per run
      t.string  :operator_cancel_rule, null: false, default: "done" # done (pay runs done) | full

      # We are the sub-contractor (the client is the main contractor)
      t.boolean :subcontracted, null: false, default: false
      t.references :client_end_customer, foreign_key: true     # Service For
      t.string  :service_for
      t.string  :contractor_contact_name
      t.string  :contractor_contact_phone
      t.boolean :require_contractor_app, null: false, default: false

      # Two-way Ad Hoc: outbound and return are two trips linked to each other
      t.references :pair, foreign_key: { to_table: :trips }
      t.boolean :is_return, null: false, default: false
      t.string  :return_billing                                # two_way | one_way (way back far from the way there)

      t.references :created_by, foreign_key: { to_table: :users }
      t.integer  :lock_version, null: false, default: 0
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :trips, %i[company_id trip_no], unique: true
    add_index :trips, %i[company_id kind]
    add_index :trips, %i[company_id starts_on ends_on]
    add_index :trips, :discarded_at
    add_check_constraint :trips, "kind IN ('ad_hoc','corporate_shuttle','airport_transfer','disposal','school_run')", name: "trips_kind"
    add_check_constraint :trips, "end_mode IN ('none','never','date','count')", name: "trips_end_mode"

    # Points of the route in order. direction 2 = return stops of a shuttle with different stops on return.
    create_table :trip_stops do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :direction, null: false, default: 1
      t.integer :position, null: false
      t.string  :name, null: false
      t.string  :use, null: false, default: "both"           # pu (pick-up) | do (drop-off) | both | via (waypoint only)
      t.text    :address
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text    :driver_note
      t.string  :street_view_url
      t.references :client_site, foreign_key: true
      t.integer :scheduled_time                               # School Run: time at this stop
      t.timestamps
    end
    add_index :trip_stops, %i[trip_id direction position], unique: true

    create_table :trip_stop_photos do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip_stop, null: false, foreign_key: true
      t.string  :photo, null: false                           # CarrierWave (ImageUploader)
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    # Pins dragged onto the road between two stops (after the stop at from_position).
    create_table :trip_route_vias do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :direction, null: false, default: 1
      t.integer :from_position, null: false
      t.integer :position, null: false
      t.decimal :lat, precision: 10, scale: 7, null: false
      t.decimal :lng, precision: 10, scale: 7, null: false
      t.timestamps
    end
    add_index :trip_route_vias, %i[trip_id direction from_position position], unique: true, name: "index_trip_route_vias_order"

    # Vehicles required: type x count (2 x 23-seater).
    create_table :trip_vehicle_requirements do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.references :vehicle_type, null: false, foreign_key: true
      t.integer :count, null: false, default: 1
      t.timestamps
    end
    add_index :trip_vehicle_requirements, %i[trip_id vehicle_type_id], unique: true

    # Vehicle slots 1..vehicles_count: the planned bus of each (empty = unassigned) and its own price (price_set each).
    create_table :trip_vehicle_slots do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.integer :slot_no, null: false
      t.references :vehicle, foreign_key: true
      t.decimal :price, precision: 12, scale: 2
      t.timestamps
    end
    add_index :trip_vehicle_slots, %i[trip_id slot_no], unique: true
    add_index :trip_vehicle_slots, :vehicle_id, name: "index_trip_vehicle_slots_on_vehicle"

    # Standby Area and reporting time.
    create_table :trip_standbys do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true, index: { unique: true }
      t.string  :location, null: false
      t.integer :minutes, null: false, default: 10
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text    :address
      t.text    :note
      t.string  :street_view_url
      t.timestamps
    end

    create_table :trip_standby_photos do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip_standby, null: false, foreign_key: true
      t.string  :photo, null: false                           # CarrierWave (ImageUploader)
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :trip_attachments do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.string :file, null: false                            # CarrierWave (DocumentUploader)
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
