# School Bus › Bus Service Requests (Convoy OS requests.js): what parents ask for in the Convoy App, or an admin adds on
# their behalf — a new service (or renewal) for an academic year, a change of address, a change of service or a stop.
# History lines and answer-date moves (mid-year requests) in their own tables.
class CreateBusRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :bus_requests do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true
      t.references :academic_year, foreign_key: true
      t.references :family, foreign_key: { on_delete: :nullify }
      t.references :school_rider, foreign_key: { on_delete: :nullify }
      t.string :code, null: false
      t.string :kind, null: false, default: "new"
      t.string :source, null: false, default: "app"
      t.string :status, null: false, default: "Requested"
      t.boolean :renew, null: false, default: false
      t.boolean :same, null: false, default: false
      t.boolean :mid, null: false, default: false
      t.string :tags, array: true, null: false, default: []
      t.string :child_name, null: false
      t.string :level
      t.string :class_name
      t.string :student_no
      t.date :birth_date
      t.text :medical
      t.integer :cca_days, array: true, null: false, default: []
      t.string :parent_name
      t.string :parent_phone
      t.string :parent_email
      t.boolean :am, null: false, default: true
      t.boolean :pm, null: false, default: true
      t.boolean :cca, null: false, default: false
      t.string :address
      t.string :postal
      t.decimal :lat, precision: 10, scale: 7
      t.decimal :lng, precision: 10, scale: 7
      t.decimal :km, precision: 6, scale: 2
      t.decimal :estimate, precision: 12, scale: 2
      t.string :start_when
      t.date :start_on
      t.string :fix_why
      t.string :fix_note
      t.boolean :fee_paid, null: false, default: true
      t.integer :policy_version
      t.timestamptz :submitted_at, null: false
      t.timestamptz :acked_at
      t.references :acked_by, foreign_key: { to_table: :users }, index: false
      t.date :answer_by
      t.text :ack_note
      t.integer :ack_plan_weeks
      t.string :reason
      t.timestamps
    end
    add_index :bus_requests, %i[company_id code], unique: true
    add_index :bus_requests, %i[school_id kind status]

    create_table :bus_request_events do |t|
      t.references :bus_request, null: false, foreign_key: { on_delete: :cascade }
      t.timestamptz :at, null: false
      t.string :by_name, null: false
      t.references :user, foreign_key: { on_delete: :nullify }, index: false
      t.text :text, null: false
    end

    create_table :bus_request_answer_moves do |t|
      t.references :bus_request, null: false, foreign_key: { on_delete: :cascade }
      t.date :from_date
      t.date :to_date, null: false
      t.string :reason, null: false
      t.timestamptz :moved_at, null: false
      t.references :moved_by, foreign_key: { to_table: :users, on_delete: :nullify }, index: false
    end
  end
end
