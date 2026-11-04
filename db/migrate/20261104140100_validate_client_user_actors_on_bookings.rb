# Validates the keys and checks of the previous migration, and drops booking_trips.rejected_by_client: declined by the
# client is now a rejection with no Convoy OS user (rejected_by_client_user_id, or the client's name recorded by us before
# the portal) — see BookingTrip#rejected_by_client?.
class ValidateClientUserActorsOnBookings < ActiveRecord::Migration[8.1]
  def up
    validate_foreign_key :bookings, column: :created_by_client_user_id
    validate_foreign_key :booking_trips, column: :acknowledged_by_id
    validate_foreign_key :booking_trips, column: :acknowledged_by_client_user_id
    validate_foreign_key :booking_trips, column: :rejected_by_client_user_id
    validate_foreign_key :booking_attachments, column: :uploaded_by_client_user_id
    validate_foreign_key :booking_cancel_requests, column: :requested_by_id
    validate_foreign_key :booking_cancel_requests, column: :requested_by_client_user_id
    AddClientUserActorsToBookings::PAIRS.each do |table, actions|
      Array(actions).each { validate_check_constraint table, name: "#{table}_#{it}_by_one" }
    end
    # safety_assured: the column is in BookingTrip.ignored_columns (deployed with this migration), nothing reads it.
    safety_assured { remove_column :booking_trips, :rejected_by_client }
  end

  def down
    add_column :booking_trips, :rejected_by_client, :boolean, null: false, default: false
  end
end
