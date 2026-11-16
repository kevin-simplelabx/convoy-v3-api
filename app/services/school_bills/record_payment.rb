# Record money received on one or more issued School Bus bills: one receipt (RCP) for the whole amount, to the payer (or
# "<names> and others" when it pays several payers' bills), and a payment on each bill it pays. No bill can be paid more
# than it owes today. allocations: [[bill, amount]]. A registration fee bill paid in full marks its requests' fee as paid.
# The Convoy App pays with source "app" and no user; admin_fee (a card / PayNow surcharge) is kept on the first payment.
module SchoolBills
  class RecordPayment < ApplicationService
    METHODS = [ "PayNow", "Bank Transfer", "GIRO", "Cheque", "Cash", "Card" ].freeze

    def initialize(school, allocations, paid_on:, method:, user:, reference: nil, today: Date.current, source: "console", admin_fee: 0)
      @school = school
      @allocations = allocations
      @paid_on = paid_on
      @method = method.to_s.strip
      @reference = reference.to_s.strip.presence
      @user = user
      @today = today
      @source = source
      @admin_fee = admin_fee.to_d.round(2)
    end

    def call
      raise Error, "Pick the date received" unless @paid_on
      raise Error, "Pick how it was paid" unless METHODS.include?(@method)
      raise Error, "Tick the bills that were paid" if @allocations.empty?

      policy = SchoolBills::Calc.policies([ @school.id ], today: @today)[@school.id]
      @allocations.each do |bill, amount|
        raise Error, "Enter the amount received" unless amount.to_d.positive?
        raise Error, "#{bill.number} is not issued yet" unless bill.issued?

        owed = SchoolBills::Calc.call(bill, policy:, today: @today).owed
        raise Error, "Amount is more than the S$#{format('%.2f', owed)} owed on #{bill.number}" if amount.to_d > owed + 0.005
      end

      ApplicationRecord.transaction do
        names = @allocations.map { |b, _| b.to_name }.uniq
        family = @allocations.map { |b, _| b.family_id }.uniq
        total = @allocations.sum(0.to_d) { |_, a| a.to_d.round(2) }
        receipt = SchoolDocument.create!(school: @school, doc_type: "rcp", number: Finance::Numbering.next!("rcp", date: @paid_on), issued_on: @paid_on,
                                         family_id: family.one? ? family.first : nil, payer: @allocations.first[0].payer,
                                         bill_to: names.size > 3 ? "#{names.first(3).join(', ')} and others" : names.join(", "),
                                         subtotal: total, total:, method: @method, reference: @reference, created_by: @user)
        @allocations.each_with_index do |(bill, amount), i|
          bill.payments.create!(receipt:, paid_on: @paid_on, amount: amount.to_d.round(2), method: @method, reference: @reference, recorded_by: @user,
                                source: @source, admin_fee: i.zero? ? @admin_fee : 0)
          registration_paid(bill) if bill.kind == "registration"
        end
        receipt
      end
    end

    private

    def registration_paid(bill)
      return unless bill.reload.paid?

      bill.registration_requests.where(fee_paid: false).find_each do |req|
        req.update!(fee_paid: true)
        req.log!("Registration fee paid (#{bill.number}, #{@method})", by: @user || "Parent")
      end
    end
  end
end
