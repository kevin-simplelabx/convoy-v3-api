# Change of Address, Change of Service and Stop Service requests, what a confirmed request did to the route plans
# (school_plan_changes: a version of the plan from the change's date) and to the rider record (patched on the day,
# ended by a click, moved to the new level when a renewed year starts).
class AddChangeRequestsToBusRequests < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Only new nullable columns or constant defaults (no table rewrite on PG 11+), on a table added this week.
    safety_assured do
      change_table :bus_requests, bulk: true do |t|
        t.date :effective_on
        t.decimal :current_fare, precision: 12, scale: 2
        t.string :old_address
        t.string :old_postal
        t.string :new_stop
        t.string :agree
        t.boolean :old_am
        t.boolean :old_pm
        t.boolean :old_cca
        t.boolean :adds, null: false, default: false
        t.date :last_on
        t.string :stop_why
        t.string :stop_why_note
        t.integer :notice_n
        t.string :notice_unit
        t.date :earliest_on
        t.boolean :early, null: false, default: false
        t.timestamptz :confirmed_at
        t.bigint :confirmed_by_id
        t.text :confirm_note
        t.date :pay_to
        t.timestamptz :planned_at
        t.boolean :planned_ok
        t.string :plan_lines, array: true, null: false, default: []
        t.date :ended_on
        t.timestamptz :ended_at
        t.bigint :ended_by_id
        t.date :rider_patched_on
        t.date :level_moved_on
      end
    end

    create_table :school_plan_changes do |t|
      t.references :school_plan, null: false, foreign_key: { on_delete: :cascade }
      t.references :bus_request, foreign_key: { on_delete: :nullify }
      t.date :from_date, null: false
      t.string :rid, null: false
      t.string :op, null: false
      t.string :text, null: false
      t.timestamptz :created_at, null: false
    end
  end
end
