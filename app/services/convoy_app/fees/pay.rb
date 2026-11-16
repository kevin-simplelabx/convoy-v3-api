# Convoy App › Pay an invoice (simulated): what is owed today is collected at once with the method picked (Payments::Simulator)
# and recorded as a payment with source "app" (one receipt) on the bill, the admin fee beside it. A registration fee bill paid
# marks its requests' fee paid; a first invoice paid makes the request Active (and joins the route plans), as in Convoy OS.
# Billing Contact only (the controller). Runs inside the bill's company.
module ConvoyApp
  module Fees
    class Pay < ApplicationService
      def initialize(member:, bill:, method:)
        @member = member
        @bill = bill
        @key = method.to_s
      end

      def call
        ApplicationRecord.transaction do
          bill = Fees.load(SchoolBill.where(id: @bill.id).lock).first # lock: two taps cannot pay it twice
          row = Fees.rows([ bill ]).first
          raise ApplicationService::Error.new("This invoice cannot be paid yet", code: "not_payable") unless row.payable

          owed = row.calc.owed
          raise ApplicationService::Error.new("This invoice is already paid", code: "already_paid") unless owed > 0.005

          option = Payments.options(bill.school).find { it.key == @key } or raise ApplicationService::Error, "Pick how to pay"
          charge = Payments::Simulator.call(option:, amount: owed)
          record(bill, charge)
        end
        @bill
      end

      private

      def record(bill, charge)
        name = @member.app_account.display_name
        if bill.kind == "first"
          BusRequests::RecordPayment.call(bill.bus_request, method: charge.label, source: "app", admin_fee: charge.admin_fee, by: name, amount: charge.amount,
                                                           reference: charge.reference)
        else
          SchoolBills::RecordPayment.call(bill.school, [ [ bill, charge.amount ] ], paid_on: Date.current, method: charge.label, user: nil,
                                                                                    reference: charge.reference, source: "app", admin_fee: charge.admin_fee)
        end
      end
    end
  end
end
