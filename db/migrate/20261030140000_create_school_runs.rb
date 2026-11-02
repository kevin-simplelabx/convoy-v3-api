class CreateSchoolRuns < ActiveRecord::Migration[8.1]
  def change
    # School Run settings on the trip.
    add_column :trips, :session, :string                                        # am (to school) | pm (from school)
    add_column :trips, :paid_months_mode, :string, null: false, default: "all"  # all | some (unticked unpaid) | part (unticked at a share)
    add_column :trips, :unpaid_months, :integer, array: true, null: false, default: [] # months 1..12 not paid in full
    add_column :trips, :unpaid_month_share, :integer, null: false, default: 50  # part: % charged in those months
    add_column :trips, :charge_no_school_days, :boolean, null: false, default: true
    add_column :trips, :school_time_estimated, :boolean, null: false, default: false # AM school arrival worked out, not given
    add_column :trips, :route_list_name, :string                                # file the current list came from
    add_column :trips, :route_list_imported_at, :datetime
    add_column :trips, :students_purged_at, :datetime                           # student data cleared 7 years after the trip ended

    # Students picked up or dropped off at a stop. key stays the same across route lists (attendance follows it).
    create_table :trip_stop_students do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip_stop, null: false, foreign_key: true
      t.uuid    :key, null: false, default: -> { "gen_random_uuid()" }
      t.integer :position, null: false, default: 0
      t.string  :name, null: false
      t.string  :class_name
      t.string  :parent_name
      t.string  :phone
      t.string  :phone2
      t.text    :note
      t.timestamps
    end
    add_index :trip_stop_students, :key

    # Earlier Lists: the route list a School Run had until a date (the Passenger List of earlier dates uses it).
    create_table :route_list_versions do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.string  :name, null: false
      t.date    :valid_until, null: false
      t.timestamps
    end
    add_index :route_list_versions, %i[trip_id valid_until]

    create_table :route_list_version_stops do |t|
      t.references :company, null: false, foreign_key: true
      t.references :route_list_version, null: false, foreign_key: true
      t.integer :position, null: false
      t.string  :name, null: false
      t.integer :scheduled_time
      t.text    :address
      t.text    :driver_note
      t.timestamps
    end

    create_table :route_list_version_students do |t|
      t.references :company, null: false, foreign_key: true
      t.references :route_list_version_stop, null: false, foreign_key: true
      t.uuid    :key, null: false
      t.integer :position, null: false, default: 0
      t.string  :name, null: false
      t.string  :class_name
      t.string  :parent_name
      t.string  :phone
      t.string  :phone2
      t.text    :note
      t.timestamps
    end

    # Passenger List: who boarded, alighted or was absent on a run (our own record, never sent to a school system).
    create_table :student_attendances do |t|
      t.references :company, null: false, foreign_key: true
      t.references :trip, null: false, foreign_key: true
      t.date :run_date, null: false
      t.references :trip_run, foreign_key: true
      t.integer :slot_no, null: false, default: 1
      t.uuid    :student_key, null: false
      t.string  :student_name, null: false
      t.datetime :boarded_at
      t.datetime :alighted_at
      t.boolean :absent, null: false, default: false
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :student_attendances, %i[trip_id run_date trip_run_id slot_no student_key], unique: true, name: "index_student_attendances_once"

    # Saved Pick-up Points: postal codes that share one stop (a condominium's gate), with its name, pin and a note.
    create_table :pickup_points do |t|
      t.references :company, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :postal_codes, array: true, null: false, default: []
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.text    :note
      t.timestamps
    end
    add_index :pickup_points, :postal_codes, using: :gin
  end
end
