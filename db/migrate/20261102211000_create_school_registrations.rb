# School Bus › Bus Service Registration per school and academic year: the windows (renewals, then everyone), when the
# service starts, hours to confirm a seat, mid-year reply times, who can apply, the graduating thank-you, auto-accept
# rules, fees shown and form questions; and the 12 parent messages (on / off, channels, timing, texts).
class CreateSchoolRegistrations < ActiveRecord::Migration[8.1]
  def change
    create_table :school_registrations do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.references :academic_year, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :status, null: false, default: "draft"
      t.date :renew_from, null: false
      t.date :renew_to, null: false
      t.date :general_from, null: false
      t.date :general_to, null: false
      t.date :service_starts_on, null: false
      t.integer :confirm_hours, null: false, default: 48
      t.integer :ack_days, null: false, default: 3
      t.integer :plan_weeks, null: false, default: 3
      t.string :levels, array: true, null: false, default: []
      t.string :sessions, array: true, null: false, default: %w[AM PM CCA]
      t.boolean :grad_on, null: false, default: true
      t.text :grad_message
      t.boolean :grad_link, null: false, default: true
      t.boolean :auto_renew, null: false, default: true
      t.boolean :renew_check_address, null: false, default: true
      t.boolean :renew_check_session, null: false, default: true
      t.boolean :renew_check_debt, null: false, default: true
      t.boolean :auto_near, null: false, default: false
      t.decimal :near_km, precision: 5, scale: 2, null: false, default: 3
      t.boolean :near_needs_cover, null: false, default: true
      t.boolean :auto_siblings, null: false, default: false
      t.boolean :siblings_need_cover, null: false, default: true
      t.string :run_mode, null: false, default: "arrive"
      t.integer :run_at, null: false, default: 540
      t.integer :seats_buffer, null: false, default: 3
      t.boolean :waitlist_auto, null: false, default: false
      t.boolean :show_fare, null: false, default: true
      t.text :extra_terms
      t.string :asks, array: true, null: false, default: %w[cls med emerg cca]
      t.references :saved_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    create_table :registration_messages do |t|
      t.references :school_registration, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :key, null: false
      t.boolean :enabled, null: false, default: true
      t.boolean :email, null: false, default: true
      t.boolean :whatsapp, null: false, default: true
      t.boolean :app, null: false, default: true
      t.integer :offset_days
      t.integer :offset_hours
      t.string :subject
      t.text :body
      t.text :whatsapp_body
      t.boolean :scheduled, null: false, default: false
      t.timestamptz :released_at
    end
    add_index :registration_messages, %i[school_registration_id key], unique: true
  end
end
