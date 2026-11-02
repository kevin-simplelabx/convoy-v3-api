class CreateMaintenance < ActiveRecord::Migration[8.1]
  def change
    create_table :workshops do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.text   :address
      t.string :phone
      t.timestamps
    end
    add_index :workshops, %i[company_id name], unique: true

    # A workshop visit of an own vehicle: planned (Plan the Visit), then recorded (Record the Work) or cancelled.
    # Shown on the Scheduler as a block on the bus.
    create_table :maintenance_visits do |t|
      t.references :company, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :driver, foreign_key: true                 # who brings the bus (default driver that day)
      t.date    :date, null: false
      t.integer :start_time, null: false
      t.integer :end_time, null: false
      t.references :workshop, foreign_key: true
      t.text    :address
      t.string  :kind, null: false, default: "service"        # service | repair | tyres | inspection | other
      t.text    :work_to_do
      t.string  :status, null: false, default: "scheduled"    # scheduled | completed | cancelled
      t.integer :odometer
      t.boolean :gst_on, null: false, default: true
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 9
      t.datetime :driver_notified_at                          # recorded; the Driver app shows it later
      t.references :completed_by, foreign_key: { to_table: :users }
      t.datetime :completed_at
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :maintenance_visits, %i[vehicle_id date]
    add_index :maintenance_visits, %i[company_id date]

    create_table :maintenance_lines do |t|
      t.references :company, null: false, foreign_key: true
      t.references :maintenance_visit, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string  :line_type, null: false, default: "part"      # part | tyre | labour | other
      t.string  :description
      t.string  :part_number
      t.string  :brand
      t.string  :model
      t.string  :tyre_position                                # Front Left, Rear Left Outer, ..., Spare
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.decimal :unit_price, precision: 12, scale: 2, null: false, default: 0   # before GST
      t.timestamps
    end

    create_table :maintenance_invoices do |t|
      t.references :company, null: false, foreign_key: true
      t.references :maintenance_visit, null: false, foreign_key: true
      t.string :file, null: false                             # CarrierWave (DocumentUploader)
      t.timestamps
    end
  end
end
