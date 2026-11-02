# Booking approval flow: who approved / rejected / acknowledged a booking trip and how, the history of changes the
# company made (the client acknowledges them), the client's cancellation requests, the booking events behind the bell,
# each user's notification picks and the emails recorded for them (not sent yet).
class AddBookingFlow < ActiveRecord::Migration[8.1]
  def change
    # safety_assured: booking_trips was created in the previous migration (same release), so it is empty.
    safety_assured do
      change_table :booking_trips, bulk: true do |t|
        t.datetime :approved_at
        t.references :approved_by, foreign_key: { to_table: :users }, index: false
        t.string :approval_how
        t.text :approval_note
        t.datetime :acknowledged_at
        t.string :acknowledged_by_name
        t.string :acknowledged_how
        t.datetime :rejected_at
        t.references :rejected_by, foreign_key: { to_table: :users }, index: false
        t.string :rejected_by_name
        t.boolean :rejected_by_client, null: false, default: false
        t.text :rejection_reason
        t.datetime :cancelled_at
      end
    end

    create_table :booking_trip_changes do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking_trip, null: false, foreign_key: true
      t.references :changed_by, foreign_key: { to_table: :users }
      t.string :items, array: true, null: false, default: []
      t.timestamps
    end

    create_table :booking_cancel_requests do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.references :booking_trip, foreign_key: true
      t.text :reason
      t.string :requested_by_name, null: false
      t.datetime :requested_at, null: false
      t.string :status, null: false, default: "open"
      t.datetime :resolved_at
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.text :resolution_note
      t.timestamps
    end
    add_index :booking_cancel_requests, %i[company_id status]

    create_table :booking_events do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.references :booking_trip, foreign_key: true
      t.string :kind, null: false
      t.string :actor_name
      t.string :message, null: false
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :booking_events, %i[company_id occurred_at]

    create_table :user_notification_preferences do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :new_booking, null: false, default: true
      t.boolean :client_approved, null: false, default: true
      t.boolean :client_declined, null: false, default: true
      t.boolean :acknowledged, null: false, default: true
      t.boolean :cancel_request, null: false, default: true
      t.boolean :email, null: false, default: true
      t.datetime :seen_at
      t.timestamps
    end

    create_table :notification_emails do |t|
      t.references :company, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :booking_event, foreign_key: true
      t.string :to, null: false
      t.string :subject, null: false
      t.text :body
      t.datetime :sent_at
      t.timestamps
    end
  end
end
