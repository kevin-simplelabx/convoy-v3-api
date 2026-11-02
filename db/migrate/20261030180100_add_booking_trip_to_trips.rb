# The Scheduler trips an approved booking trip became (one, or the outbound and return of a Two Way).
class AddBookingTripToTrips < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :trips, :booking_trip, index: { algorithm: :concurrently }
    add_foreign_key :trips, :booking_trips, validate: false
  end
end
