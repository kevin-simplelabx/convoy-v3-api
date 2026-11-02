class CreateFleet < ActiveRecord::Migration[8.1]
  def change
    # Platform-wide (no company): only Convoy adds or removes types.
    create_table :vehicle_types do |t|
      t.string  :key, null: false
      t.string  :name, null: false
      t.integer :seats, null: false
      t.string  :tyre_layout, null: false, default: "1-1"
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :vehicle_types, :key, unique: true

    # A company turns platform types off (all on by default).
    create_table :disabled_vehicle_types do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle_type, null: false, foreign_key: true
      t.timestamps
    end
    add_index :disabled_vehicle_types, %i[company_id vehicle_type_id], unique: true

    create_table :vehicle_teams do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false, default: "#0B6E6E"
      t.timestamps
    end
    add_index :vehicle_teams, %i[company_id name], unique: true

    # Transport operators we work with: managed (on file, no Convoy account) or external (one-off hire).
    create_table :operators do |t|
      t.references :company, null: false, foreign_key: true
      t.string   :name, null: false
      t.string   :kind, null: false, default: "managed"  # managed | external
      t.string   :uen
      t.string   :contact_name
      t.string   :phone
      t.string   :email
      t.string   :payment_method                       # paynow | bank
      t.string   :paynow_uen
      t.string   :bank_code
      t.string   :branch_code
      t.string   :account_number
      t.string   :account_name
      t.date     :valid_until                            # hire agreement ends (drop warning after this date)
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :operators, %i[company_id kind name], unique: true, where: "discarded_at IS NULL"
    add_index :operators, :discarded_at

    # Every bus: own (no operator), managed or external (by its operator's kind).
    create_table :vehicles do |t|
      t.references :company, null: false, foreign_key: true
      t.references :operator, foreign_key: true
      t.references :vehicle_team, foreign_key: true
      t.string   :plate, null: false
      t.integer  :seats
      t.string   :make
      t.string   :model
      t.integer  :year_made
      t.string   :tags, array: true, null: false, default: []
      t.text     :notes
      t.string   :photo                                  # CarrierWave (ImageUploader)
      t.string   :driver_name                            # external vehicles only (no driver record)
      t.string   :driver_phone                           # external vehicles only
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :vehicles, %i[company_id plate], unique: true, where: "discarded_at IS NULL"
    add_index :vehicles, :tags, using: :gin
    add_index :vehicles, %i[company_id seats]
    add_index :vehicles, :discarded_at

    # Own drivers: added with name and mobile (invite), they set up their own Convoy Driver account.
    create_table :drivers do |t|
      t.references :company, null: false, foreign_key: true
      t.string   :name, null: false
      t.string   :phone, null: false
      t.string   :photo                                  # CarrierWave (ImageUploader)
      t.string   :status, null: false, default: "pending" # pending | active | declined | past
      t.datetime :invited_at
      t.datetime :responded_at
      t.timestamps
    end
    add_index :drivers, %i[company_id phone], unique: true
    add_index :drivers, %i[company_id status]

    # Default driver of an own vehicle from a date (changes can be scheduled ahead; driver null = no driver from then).
    create_table :vehicle_driver_schedules do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :driver, foreign_key: true
      t.date       :starts_on, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :vehicle_driver_schedules, %i[vehicle_id starts_on], unique: true
    add_index :vehicle_driver_schedules, %i[driver_id starts_on]

    # Drivers of managed operators: invited like own drivers; at most one bus of their own operator.
    create_table :operator_drivers do |t|
      t.references :company, null: false, foreign_key: true
      t.references :operator, null: false, foreign_key: true
      t.references :vehicle, foreign_key: true
      t.string   :name, null: false
      t.string   :phone, null: false
      t.string   :photo                                  # CarrierWave (ImageUploader)
      t.text     :notes
      t.string   :status, null: false, default: "pending" # pending | active | declined | past
      t.datetime :invited_at
      t.datetime :responded_at
      t.timestamps
    end
    add_index :operator_drivers, %i[company_id phone], unique: true
    add_index :operator_drivers, :vehicle_id, unique: true, name: "index_operator_drivers_one_per_vehicle",
              where: "vehicle_id IS NOT NULL"

    # Bus attendants (crew on school routes and School Runs).
    create_table :attendants do |t|
      t.references :company, null: false, foreign_key: true
      t.string   :name, null: false
      t.string   :phone
      t.string   :photo                                  # CarrierWave (ImageUploader)
      t.text     :notes
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :attendants, :discarded_at
  end
end
