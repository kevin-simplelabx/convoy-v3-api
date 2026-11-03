# Accepting a bus request: the final quote on the request, where the child goes on each session's running routes
# (Route Fit, so the seat is held until the route plan has the child), and the first invoice as a real bill to the
# family (INV number, GST from Finance Settings, paid by a recorded payment). School Finance builds on school_bills.
class CreateSchoolBills < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :school_bills do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true
      t.references :academic_year, foreign_key: true, index: false
      t.references :family, foreign_key: { on_delete: :nullify }
      t.references :school_rider, foreign_key: { on_delete: :nullify }, index: false
      t.references :bus_request, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.string :number, null: false
      t.string :kind, null: false, default: "first"
      t.string :status, null: false, default: "open"
      t.string :bill_to
      t.string :period_label
      t.date :period_starts_on
      t.date :issued_on, null: false
      t.timestamptz :due_at
      t.decimal :subtotal, precision: 12, scale: 2, null: false
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 0
      t.decimal :gst_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false
      t.timestamptz :paid_at
      t.string :method
      t.references :recorded_by, foreign_key: { to_table: :users }, index: false
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :school_bills, %i[company_id number], unique: true

    create_table :bus_request_places do |t|
      t.references :bus_request, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :session, null: false
      t.references :school_route, foreign_key: { on_delete: :nullify }
      t.string :route_label
      t.string :kind, null: false
      t.string :stop_name
      t.decimal :delta_minutes, precision: 5, scale: 1
    end
    add_index :bus_request_places, %i[bus_request_id session], unique: true

    add_column :bus_requests, :quote_amount, :decimal, precision: 12, scale: 2
    add_column :bus_requests, :quote_base, :decimal, precision: 12, scale: 2
    add_column :bus_requests, :quote_unit, :string
    add_column :bus_requests, :quote_note, :text
    add_column :bus_requests, :quoted_at, :timestamptz
    add_reference :bus_requests, :quoted_by, index: false
    add_column :bus_requests, :offer_by, :timestamptz
  end
end
