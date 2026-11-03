# Record money received on one or more issued School Bus bills: one receipt (RCP) for the whole amount, to the payer (or
# "<names> and others" when it pays several payers' bills), and a payment on each bill it pays. No bill can be paid more
# than it owes today. allocations: [[bill, amount]].
module SchoolBills
  class RecordPayment < ApplicationService
    METHODS = [ "PayNow", "Bank Transfer", "GIRO", "Cheque", "Cash", "Card" ].freeze

    def initialize(school, allocations, paid_on:, method:, user:, reference: nil, today: Date.current)
      @school = school
      @allocations = allocations
      @paid_on = paid_on
      @method = method.to_s.strip
      @reference = reference.to_s.strip.presence
      @user = user
      @today = today
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
        total = @allocations.sum { |_, a| a.to_d.round(2) }
        receipt = SchoolDocument.create!(school: @school, doc_type: "rcp", number: Finance::Numbering.next!("rcp", date: @paid_on), issued_on: @paid_on,
                                         family_id: family.one? ? family.first : nil, payer: @allocations.first[0].payer,
                                         bill_to: names.size > 3 ? "#{names.first(3).join(', ')} and others" : names.join(", "),
                                         subtotal: total, total:, method: @method, reference: @reference, created_by: @user)
        @allocations.each do |bill, amount|
          bill.payments.create!(receipt:, paid_on: @paid_on, amount: amount.to_d.round(2), method: @method, reference: @reference, recorded_by: @user)
        end
        receipt
      end
    end
  end
end
