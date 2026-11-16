# Stand-in for the payment provider (Stripe SG or HitPay, not chosen): "collects" what was asked at once, whatever the
# method (card, PayNow, and bank transfer too — no pending match). Callers record the money in school_bill_payments with
# source "app"; swapping in a real provider replaces only this class.
module ConvoyApp
  module Payments
    class Simulator < ApplicationService
      # amount: what clears the bill; admin_fee: the method's surcharge on top; charged: what the parent pays in all.
      Charge = Data.define(:key, :label, :amount, :admin_fee, :charged, :reference, :paid_at)

      def initialize(option:, amount:, now: Time.current)
        @option = option
        @amount = amount.to_d
        @now = now
      end

      def call
        raise ApplicationService::Error, "Pick how to pay" unless @option
        raise ApplicationService::Error, "There is nothing to pay" unless @amount.positive?

        fee = @option.fee_for(@amount)
        Charge.new(key: @option.key, label: @option.label, amount: @amount, admin_fee: fee, charged: @amount + fee,
                   reference: "SIM-#{SecureRandom.alphanumeric(8).upcase}", paid_at: @now)
      end
    end
  end
end
