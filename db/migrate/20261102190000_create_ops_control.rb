# Ops Control: when the driver started a run in the Convoy Driver app (ended_at is there already), the driver app
# sign-ins (is the driver logged in before the first pick-up?), and the alerts raised on runs — kept so they can be
# acknowledged, escalated, counted and listed in the Alert Log after they clear.
class CreateOpsControl < ActiveRecord::Migration[8.1]
  def change
    add_column :trip_occurrences, :started_at, :timestamptz

    create_table :driver_app_sessions do |t|
      t.references :company, null: false, foreign_key: true
      t.references :driver, foreign_key: true, index: false
      t.references :operator_driver, foreign_key: true, index: false
      t.references :tracking_device, foreign_key: { on_delete: :nullify }
      t.timestamptz :signed_in_at, null: false
      t.timestamptz :signed_out_at
      t.timestamptz :last_seen_at
      t.timestamps
    end
    add_index :driver_app_sessions, %i[driver_id signed_in_at], where: "driver_id IS NOT NULL"
    add_index :driver_app_sessions, %i[operator_driver_id signed_in_at], where: "operator_driver_id IS NOT NULL"
    add_check_constraint :driver_app_sessions, "num_nonnulls(driver_id, operator_driver_id) = 1", name: "driver_app_sessions_one_driver"

    create_table :ops_alerts do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.string :kind, null: false
      t.integer :severity, limit: 2, null: false
      t.text :message, null: false
      t.timestamptz :raised_at, null: false
      t.timestamptz :cleared_at
      t.timestamptz :acknowledged_at
      t.references :acknowledged_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :escalated_at
      t.timestamps
    end
    add_index :ops_alerts, %i[occurrence_id occurrence_date kind severity], unique: true, where: "cleared_at IS NULL",
                                                                             name: "index_ops_alerts_open"
    add_index :ops_alerts, %i[company_id raised_at]
    add_index :ops_alerts, :company_id, where: "cleared_at IS NULL", name: "index_ops_alerts_on_company_open"
  end
end
