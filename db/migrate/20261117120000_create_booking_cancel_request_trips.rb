# Review fixes R1 + R13 (17/11/2026).
# booking_cancel_request_trips: the exact trips a cancellation request asks about (what was quoted), so accepting it never
#   cancels a trip that already ran or was under way when it was sent (at most 10 days x 10 trips per request).
# booking_trips.paid_amount: what a prepaid booking (payer self) paid for the trip at submit; refunds and the cancel charge
#   use it, never the estimate worked out again later. Nil on bookings the client is invoiced for.
class CreateBookingCancelRequestTrips < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_cancel_request_trips do |t|
      t.references :company, null: false, foreign_key: true
      t.references :booking_cancel_request, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :booking_trip, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
    add_index :booking_cancel_request_trips, %i[booking_cancel_request_id booking_trip_id], unique: true,
                                                                                         name: "index_booking_cancel_request_trips_unique"

    add_column :booking_trips, :paid_amount, :decimal, precision: 12, scale: 2
  end
end
