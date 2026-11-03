# Raise a credit note (taken off this bill, refunded to the payer, or taken off their next bill) or a debit note (added
# to this bill) on an issued bill: what it is for, the amount (GST on top or inside it, as Finance Settings say) and why.
# A credit taken off this bill cannot be more than is owed on it.
module SchoolBills
  class AddNote < ApplicationService
    def initialize(bill, params, user:, today: Date.current)
      @bill = bill
      @p = params
      @user = user
      @today = today
    end

    def call
      type = @p[:doc_type].to_s
      cn = type == "cn"
      raise Error, "Pick a credit note or a debit note" unless %w[cn dn].include?(type)
      raise Error, "Only an issued bill can have notes" unless @bill.issued?
      raise Error, "Enter what the #{cn ? 'credit' : 'debit'} is for" if @p[:description].to_s.strip.empty?
      raise Error, "Enter the amount" unless @p[:amount].to_d.positive?
      raise Error, "Enter a reason" if @p[:reason].to_s.strip.empty?

      use = cn ? @p[:credit_use].presence || "reduce" : nil
      raise Error, "Pick what happens to the credit" if cn && !SchoolDocument::USES.include?(use)

      s = FinanceSetting.current
      split = FinanceSetting.split(@p[:amount].to_d, on: s.gst_on?, rate: s.gst_rate, mode: s.gst_mode)
      if cn && use == "reduce"
        owed = Calc.call(@bill, policy: @bill.school.policy_versions.in_use_on(@today), today: @today).owed
        if split[:total] > owed + 0.005
          raise Error, "Only S$#{format('%.2f', owed)} is owed on this bill. Refund the rest or take it off the next bill"
        end
      end
      on = @p[:issued_on].presence&.to_date || @today
      refund = cn && use == "refund"
      SchoolDocument.create!(school: @bill.school, school_bill: @bill, doc_type: type, number: Finance::Numbering.next!(type, date: on), issued_on: on,
                             family: @bill.family, payer: @bill.payer, bill_to: @bill.to_name, description: @p[:description].to_s.strip,
                             subtotal: split[:sub], gst_rate: s.gst_on? ? s.gst_rate : 0, gst_amount: split[:gst], total: split[:total],
                             reason: @p[:reason].to_s.strip, credit_use: use, refund_on: refund ? on : nil, method: refund ? @p[:method].presence || "Bank Transfer" : nil,
                             reference: refund ? @p[:reference].to_s.strip.presence : nil, created_by: @user)
    rescue Date::Error
      raise Error, "Pick the date"
    end
  end
end
