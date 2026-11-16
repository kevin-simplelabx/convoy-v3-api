# Validates the Phase 7 keys and checks, then gives the existing cancel requests their scope (a trip when they name one).
class ValidateAppBookingsColumns < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    validate_foreign_key :clients, :app_accounts
    validate_foreign_key :bookings, :client_bill_funds
    validate_foreign_key :bookings, column: :created_by_app_account_id
    validate_foreign_key :bookings, column: :booked_via_client_user_id
    validate_foreign_key :bookings, column: :copied_from_booking_id
    validate_check_constraint :bookings, name: "bookings_payer"
    validate_check_constraint :bookings, name: "bookings_created_by_one"
    validate_foreign_key :booking_cancel_requests, :booking_days
    validate_foreign_key :booking_cancel_requests, column: :requested_by_app_account_id
    validate_check_constraint :booking_cancel_requests, name: "booking_cancel_requests_requested_by_one"
    validate_foreign_key :client_pickup_points, column: :created_by_client_user_id

    # Small table (cancel requests are entered by hand); one statement.
    safety_assured { execute "UPDATE booking_cancel_requests SET scope = 'trip' WHERE booking_trip_id IS NOT NULL" }
    add_check_constraint :booking_cancel_requests, "scope IN ('booking', 'day', 'trip')", name: "booking_cancel_requests_scope", validate: false
    add_check_constraint :booking_cancel_requests,
                         "(scope = 'trip') = (booking_trip_id IS NOT NULL) AND (scope = 'day') = (booking_day_id IS NOT NULL)",
                         name: "booking_cancel_requests_scope_target", validate: false
    validate_check_constraint :booking_cancel_requests, name: "booking_cancel_requests_scope"
    validate_check_constraint :booking_cancel_requests, name: "booking_cancel_requests_scope_target"
  end

  def down
    remove_check_constraint :booking_cancel_requests, name: "booking_cancel_requests_scope_target"
    remove_check_constraint :booking_cancel_requests, name: "booking_cancel_requests_scope"
  end
end
