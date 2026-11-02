class CreateNotices < ActiveRecord::Migration[8.1]
  def change
    create_table :notice_templates do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.text   :message, null: false
      t.timestamps
    end
    add_index :notice_templates, %i[company_id name], unique: true

    # A banner or message to riders and / or parents for a trip (all its timings or some), for a period.
    # School route audiences arrive with School Bus routes (Phase 9).
    create_table :notices do |t|
      t.references :company, null: false, foreign_key: true
      t.string :audience, null: false, default: "trip"      # trip | school (Phase 9)
      t.references :trip, foreign_key: true
      t.boolean :all_runs, null: false, default: true
      t.boolean :to_riders, null: false, default: true
      t.boolean :to_parents, null: false, default: false
      t.boolean :banner, null: false, default: true          # In-App Banner
      t.boolean :push, null: false, default: false           # Push Notification
      t.boolean :sms, null: false, default: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.references :notice_template, foreign_key: true
      t.string :message, null: false, limit: 300
      t.datetime :ended_at                                   # End Now
      t.references :ended_by, foreign_key: { to_table: :users }
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :notices, %i[company_id starts_at ends_at]
    add_check_constraint :notices, "ends_at > starts_at", name: "notices_period"

    # The timings a notice is for when not all of them.
    create_table :notice_runs do |t|
      t.references :company, null: false, foreign_key: true
      t.references :notice, null: false, foreign_key: true
      t.references :trip_run, null: false, foreign_key: true
      t.timestamps
    end
    add_index :notice_runs, %i[notice_id trip_run_id], unique: true

    # Push and SMS sends (recorded only until the Convoy App and an SMS gateway are wired).
    create_table :notice_deliveries do |t|
      t.references :company, null: false, foreign_key: true
      t.references :notice, null: false, foreign_key: true
      t.string  :channel, null: false                        # push | sms
      t.integer :recipients
      t.timestamps
    end
  end
end
