# Prepaid bookings paid before booking_trips.paid_amount existed: each trip paid its estimate at submit (Bookings::Prepaid.pay!
# charged the booking's estimate, the sum of its trips'). Data only, small table.
class BackfillBookingTripsPaidAmount < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute(<<~SQL.squish)
        UPDATE booking_trips t SET paid_amount = t.estimate_amount
        FROM bookings b
        WHERE b.id = t.booking_id AND b.payer = 'self' AND t.paid_amount IS NULL
          AND EXISTS (SELECT 1 FROM booking_payments p WHERE p.booking_id = b.id AND p.kind = 'payment')
      SQL
    end
  end

  def down; end
end
