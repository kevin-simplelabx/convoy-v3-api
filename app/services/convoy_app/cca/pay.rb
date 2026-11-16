# Convoy App › CCA Bus, Pay to confirm (simulated): the picked rides are booked and paid at once — the Family's credit first,
# then the method picked (never Bank Transfer) through Payments::Simulator — as one CCA bill with its payment (source "app",
# the admin fee beside it) and a booking per ride. Rides covered by credit alone are booked with no payment ("Book with Credit").
# Billing Contact only (the controller). The school is locked while seats and credit are checked and spent.
module ConvoyApp
  module Cca
    class Pay < ApplicationService
      Result = Data.define(:bill, :rides, :charge, :company)

      def initialize(member:, school_id:, picks:, method: nil)
        @household = member.household
        @school_id = school_id
        @picks = picks
        @key = method.to_s
      end

      def call
        offer = Cca.offer!(@household, @school_id)
        Parents.within(offer.company) do
          charge = nil
          bill = ApplicationRecord.transaction do
            offer.school.lock!
            pay = CcaRides::Pay.new(offer.family, picks: Cca.picks(offer, @picks), today: Date.current)
            q = pay.quote
            if q.total.positive?
              option = Cca.methods(offer.school).find { it.key == @key } or raise ApplicationService::Error, "Pick how to pay: PayNow or card"
              charge = Payments::Simulator.call(option:, amount: q.total)
            end
            pay.record(q, method: charge&.label, source: "app", admin_fee: charge&.admin_fee || 0, reference: charge&.reference)
          end
          Result.new(bill: bill.reload, rides: CcaBooking.where(school_bill_id: bill.id).count, charge:, company: offer.company)
        end
      end
    end
  end
end
