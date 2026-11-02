# Trip History: runs a calendar skips are kept as rows (status skipped, with why) so history and reports can count
# them; who a cancelled run was cancelled for (client or us); the company's on-time rule; notes on a run; the
# driver's report (note and photos) — written by the driver app later, seeded for now.
class AddTripHistory < ActiveRecord::Migration[8.1]
  def change
    # Nullable / constant default: no rewrite of the partitions.
    add_column :trip_occurrences, :skip_reason, :string
    add_column :trip_occurrences, :cancelled_by_client, :boolean, null: false, default: false
    add_column :companies, :on_time_minutes, :integer, null: false, default: 5

    create_table :occurrence_notes do |t|
      t.references :company, null: false, foreign_key: true
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.text :body, null: false
      t.references :author, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :occurrence_notes, %i[occurrence_id occurrence_date]

    create_table :occurrence_driver_reports do |t|
      t.references :company, null: false, foreign_key: true
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.string :driver_name
      t.text :note
      t.datetime :submitted_at, null: false
      t.timestamps
    end
    add_index :occurrence_driver_reports, %i[occurrence_id occurrence_date], unique: true

    create_table :occurrence_report_photos do |t|
      t.references :company, null: false, foreign_key: true
      t.references :occurrence_driver_report, null: false, foreign_key: true
      t.string :image, null: false
      t.string :caption
      t.timestamps
    end
  end
end
