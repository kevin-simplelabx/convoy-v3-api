class ValidateBookingTripOnTrips < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :trips, :booking_trips
  end
end
