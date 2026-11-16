# Money of a prepaid booking (payer self: Personal, or Pay Myself from a school account), simulated like every Convoy App
# payment (ConvoyApp::Payments::Simulator stands in for the provider). Paid once when it is sent: the estimate plus the
# method's card fee. Refunded when trips go: what those trips paid (booking_trips.paid_amount), less any cancellation
# charge, card fee back in proportion. Settled here, never on a Client Invoice (ClientInvoices::Billable leaves them out).
#   Bookings::Prepaid.pay!(booking:, option:)            -> BookingPayment (payment)
#   Bookings::Prepaid.refund!(booking:, trips:, fee: 0) -> BookingPayment (refund) or nil (nothing to give back)
module Bookings
  module Prepaid
    module_function

    def pay!(booking:, option:)
      charge = ConvoyApp::Payments::Simulator.call(option:, amount: booking.estimate_amount)
      # Each trip keeps what it paid (its estimate now): refunds never follow an estimate worked out again later.
      booking.trips.each { it.update!(paid_amount: it.estimate_amount) }
      booking.payments.create!(company_id: booking.company_id, kind: "payment", method: option.key, method_label: option.label,
                               amount: charge.amount, card_fee: charge.admin_fee, reference: charge.reference, paid_at: charge.paid_at)
    end

    def refund!(booking:, trips:, fee: 0, note: nil, now: Time.current)
      return unless booking.paid_by_self?

      payment = booking.payments.find(&:payment?) or return
      share = trips.sum(&:paid_share).to_d
      amount = [ [ share - fee.to_d, 0 ].max, left(booking) ].min.round(2)
      return unless amount.positive?

      card_fee = payment.amount.positive? ? (payment.card_fee * amount / payment.amount).round(2) : 0.to_d
      booking.payments.create!(company_id: booking.company_id, kind: "refund", method: payment.method, method_label: payment.method_label,
                               amount:, card_fee:, reference: "SIM-#{SecureRandom.alphanumeric(8).upcase}", paid_at: now, note:)
    end

    # What was paid less what was refunded (booking money, no card fee).
    def left(booking)
      list = booking.payments.to_a
      list.select(&:payment?).sum(&:amount) - list.select(&:refund?).sum(&:amount)
    end

    # The same in money charged (card fee included): what the person is out of pocket now.
    def net_charged(booking)
      list = booking.payments.to_a
      list.select(&:payment?).sum(&:charged) - list.select(&:refund?).sum(&:charged)
    end
  end
end
