# Convoy App › Shuttles (staff rider): the inbox every alert goes into (app_notifications, read by the Alerts tab in a later
# phase), My Usual Shuttle, pinned routes, stop bells, Alert Settings per route (timings as rows), and Pause Alerts.
# Rows that belong to a company's trips carry company_id and are read inside that company; deleting a run, stop or trip in
# Convoy OS removes the rider's rows that point at it.
class CreateAppShuttles < ActiveRecord::Migration[8.1]
  def change
    create_table :app_notifications do |t|
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :company, foreign_key: true
      t.string :kind, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.references :trip, foreign_key: { on_delete: :nullify }
      t.bigint :occurrence_id
      t.date :occurrence_date
      t.string :dedupe_key, null: false
      t.datetime :read_at
      t.datetime :pushed_at
      t.timestamps
    end
    add_index :app_notifications, %i[app_account_id dedupe_key], unique: true
    add_index :app_notifications, %i[app_account_id created_at]

    create_table :shuttle_usuals do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip_run, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip_stop, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :shuttle_usuals, %i[app_account_id client_id], unique: true

    create_table :shuttle_pins do |t|
      t.references :company, null: false, foreign_key: true
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :shuttle_pins, %i[app_account_id trip_id], unique: true

    create_table :shuttle_stop_bells do |t|
      t.references :company, null: false, foreign_key: true
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip_stop, null: false, foreign_key: { on_delete: :cascade }
      t.integer :direction, null: false
      t.boolean :on, null: false, default: true
      t.timestamps
    end
    add_index :shuttle_stop_bells, %i[app_account_id trip_id direction trip_stop_id], unique: true, name: "index_shuttle_stop_bells_unique"
    add_check_constraint :shuttle_stop_bells, "direction IN (1, 2)", name: "shuttle_stop_bells_direction"

    create_table :shuttle_alert_settings do |t|
      t.references :company, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :app_account, null: false, foreign_key: { on_delete: :cascade }
      t.references :trip, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :enabled, null: false, default: true
      t.integer :weekdays, array: true, null: false, default: []
      t.integer :lead_minutes, null: false, default: 5
      t.boolean :notify_bus_change, null: false, default: true
      t.boolean :notify_service_days, null: false, default: true
      t.boolean :notify_late, null: false, default: true
      t.boolean :notify_notices, null: false, default: true
      t.timestamps
    end
    add_index :shuttle_alert_settings, %i[app_account_id trip_id], unique: true
    add_check_constraint :shuttle_alert_settings, "lead_minutes IN (5, 10, 15)", name: "shuttle_alert_settings_lead"

    create_table :shuttle_alert_setting_runs do |t|
      t.references :shuttle_alert_setting, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :trip_run, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :shuttle_alert_setting_runs, %i[shuttle_alert_setting_id trip_run_id], unique: true, name: "index_shuttle_alert_setting_runs_unique"

    add_column :app_accounts, :shuttle_alerts_paused_until, :date
  end
end
