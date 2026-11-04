# Who did it, on the booking tables (decision 04/11/2026): <x>_by_id → users (Convoy OS, or recording for the client),
# <x>_by_client_user_id → client_users (the client in the Client Portal), <x>_by_name the name kept for display; never
# both ids. bookings: who booked; booking_trips: who accepted changes / declined; attachments: who uploaded;
# cancel requests: who asked.
class AddClientUserActorsToBookings < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  PAIRS = { bookings: :created, booking_trips: [ :acknowledged, :rejected ], booking_attachments: :uploaded,
            booking_cancel_requests: :requested }.freeze

  def change
    add_column :bookings, :created_by_name, :string
    add_reference :bookings, :created_by_client_user, index: { algorithm: :concurrently }
    add_reference :booking_trips, :acknowledged_by, index: { algorithm: :concurrently }
    add_reference :booking_trips, :acknowledged_by_client_user, index: { algorithm: :concurrently }
    add_reference :booking_trips, :rejected_by_client_user, index: { algorithm: :concurrently }
    add_reference :booking_attachments, :uploaded_by_client_user, index: { algorithm: :concurrently }
    add_reference :booking_cancel_requests, :requested_by, index: { algorithm: :concurrently }
    add_reference :booking_cancel_requests, :requested_by_client_user, index: { algorithm: :concurrently }

    add_foreign_key :bookings, :client_users, column: :created_by_client_user_id, validate: false
    add_foreign_key :booking_trips, :users, column: :acknowledged_by_id, validate: false
    add_foreign_key :booking_trips, :client_users, column: :acknowledged_by_client_user_id, validate: false
    add_foreign_key :booking_trips, :client_users, column: :rejected_by_client_user_id, validate: false
    add_foreign_key :booking_attachments, :client_users, column: :uploaded_by_client_user_id, validate: false
    add_foreign_key :booking_cancel_requests, :users, column: :requested_by_id, validate: false
    add_foreign_key :booking_cancel_requests, :client_users, column: :requested_by_client_user_id, validate: false

    PAIRS.each do |table, actions|
      Array(actions).each do |a|
        add_check_constraint table, "num_nonnulls(#{a}_by_id, #{a}_by_client_user_id) <= 1", name: "#{table}_#{a}_by_one", validate: false
      end
    end
  end
end
