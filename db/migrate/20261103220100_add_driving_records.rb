# Driving in the Convoy Driver app. At each point: why it was skipped and by whom (the driver, automatically because no
# one was riding, or before the trip in Edit Route), who recorded it (driver app, GPS), passengers on the bus after it,
# and leaving a pick-up early with children still missing. On the run: how the driver ended it (completed, force ended,
# skipped) with the reason and who was still on board. Every driving action is logged once by its client id, so the app
# can send it again (offline) without doing it twice.
class AddDrivingRecords < ActiveRecord::Migration[8.1]
  def up
    add_column :occurrence_stop_events, :skip_reason, :string
    add_column :occurrence_stop_events, :skipped_by, :string
    add_column :occurrence_stop_events, :planned_skip, :boolean, null: false, default: false
    add_column :occurrence_stop_events, :on_board, :integer
    add_column :occurrence_stop_events, :left_early_missing, :integer
    add_column :occurrence_stop_events, :source, :string, null: false, default: "telematics"

    # safety_assured: the partitioned parent can't take NOT VALID constraints; new columns are NULL (quick).
    safety_assured do
      execute <<~SQL
        ALTER TABLE trip_occurrences
          ADD COLUMN driver_end varchar,
          ADD COLUMN driver_end_reason varchar,
          ADD COLUMN end_on_board integer
      SQL
    end

    create_table :driver_app_actions do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :driver_account, null: false, foreign_key: true, index: false
      t.uuid :client_id, null: false
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.string :kind, null: false
      t.datetime :at, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :driver_app_actions, %i[driver_account_id client_id], unique: true
    add_index :driver_app_actions, %i[occurrence_id occurrence_date]
  end

  def down
    drop_table :driver_app_actions
    safety_assured { execute "ALTER TABLE trip_occurrences DROP COLUMN driver_end, DROP COLUMN driver_end_reason, DROP COLUMN end_on_board" }
    %i[skip_reason skipped_by planned_skip on_board left_early_missing source].each { remove_column :occurrence_stop_events, it }
  end
end
