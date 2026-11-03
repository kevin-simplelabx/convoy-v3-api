# Statement of Account of one payer at a school (port of the stm in docsVals): every bill issued, debit note, credit
# taken off a bill, payment and the late fee to date, oldest first, with the running balance owed.
module SchoolBills
  class Statement < ApplicationService
    def initialize(school, payer_key, today: Date.current)
      @school = school
      @key = payer_key.to_s
      @today = today
    end

    def call
      scope = SchoolBill.issued.where(school: @school)
      scope = @key == "school" ? scope.where(payer: "school") : scope.where(payer: "family", family_id: @key.delete_prefix("family:"))
      bills = scope.includes(:lines, :waivers, payments: :receipt, notes: []).order(:issued_on, :id).to_a
      raise ApplicationService::Error, "No bills for this payer" if bills.empty?

      policy = @school.policy_versions.in_use_on(@today)
      events = bills.flat_map { events_of(it, Calc.call(it, policy:, today: @today)) }.sort_by { it[:date] }
      balance = 0.to_d
      lines = events.map do |e|
        balance = (balance + e[:amount]).round(2)
        { date: e[:date], details: e[:details], charge: e[:amount].positive? ? e[:amount] : nil, credit: e[:amount].negative? ? -e[:amount] : nil, balance: }
      end
      { payer: @key, name: bills.first.to_name, as_of: @today, lines:, balance: }
    end

    private

    def events_of(b, c)
      out = [ { date: b.issued_on, details: "#{b.number} | #{b.period_label}", amount: b.total } ]
      b.notes.reject(&:voided?).each do |n|
        out << { date: n.issued_on, details: "#{n.number} | Debit note", amount: n.total } if n.debit_note?
        out << { date: n.issued_on, details: "#{n.number} | Credit note", amount: -n.total } if n.credit_note? && n.credit_use == "reduce"
      end
      b.payments.reject(&:voided?).each { out << { date: it.paid_on, details: "#{it.receipt&.number || 'Payment'} | #{it.method}", amount: -it.amount } }
      out << { date: @today, details: "#{b.number} | Late fee to date", amount: c.late } if c.late.positive?
      out
    end
  end
end
