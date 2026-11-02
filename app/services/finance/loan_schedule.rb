# A vehicle loan's instalments (port of logic/vehicle-loan.js): the term charge (flat rate when not given), first /
# monthly / last instalments, interest spread evenly (the rounding on the last), one row per instalment (Paid / Overdue /
# Due / Upcoming against today) and what is still owed.
module Finance
  class LoanSchedule
    Row = Struct.new(:n, :due_on, :amount, :interest, :principal, :balance, :paid_on, :status, keyword_init: true)

    attr_reader :rows

    def initialize(fin, today: Date.current)
      @f = fin
      @today = today
      @paid = fin.payments.to_h { |p| [ p.instalment_no, p.paid_on ] }
      build
    end

    def loan = @f.loan_amount.to_d
    def tenure = @f.tenure_months.to_i
    def term_charge_auto = (loan * @f.rate.to_d / 100 * tenure / 12).round(2)
    def term_charge = @f.term_charge || term_charge_auto
    def total = (loan + term_charge).round(2)
    def monthly_auto = tenure.positive? ? (total / tenure).ceil.to_d : 0.to_d
    def monthly = @f.monthly_instalment || monthly_auto
    def first = @f.first_instalment || monthly
    def last_auto = tenure > 1 ? (total - first - ((tenure - 2) * monthly)).round(2) : total
    def last = @f.last_instalment || last_auto
    def valid? = @f.funding == "loan" && loan.positive? && tenure.positive? && @f.first_due_on.present?
    def scheduled = (first + (monthly * [ tenure - 2, 0 ].max) + (tenure > 1 ? last : 0)).round(2)
    def down = @f.down_payment || [ @f.purchase_price.to_d - loan, 0 ].max

    def paid_rows = rows.select(&:paid_on)
    def paid_amount = paid_rows.sum(0.to_d, &:amount)
    def owed = ((valid? ? scheduled : total) - paid_amount).round(2)
    def overdue = rows.select { |r| r.status == "overdue" }
    def next_due = rows.find { |r| r.paid_on.nil? }

    def summary
      { loan:, rate: @f.rate, tenure:, term_charge:, term_charge_auto:, total:, scheduled:, first:, monthly:, monthly_auto:, last:, last_auto:,
        down:, valid: valid?, paid_count: paid_rows.size, paid_amount:, owed:, principal_owed: (loan - paid_rows.sum(0.to_d, &:principal)).round(2),
        interest_paid: paid_rows.sum(0.to_d, &:interest), interest_owed: (term_charge - paid_rows.sum(0.to_d, &:interest)).round(2),
        next_due: next_due&.to_h, overdue_count: overdue.size, ends_on: rows.last&.due_on,
        check: valid? && (scheduled - total).abs > 1 ? "The instalments add up to S$#{format('%.2f', scheduled)}, but loan plus term charge is S$#{format('%.2f', total)}. Check the figures against the schedule" : nil }
    end

    private

    def build
      @rows = []
      return unless valid?

      balance = scheduled
      interest_left = term_charge
      (1..tenure).each do |i|
        amount = i == 1 ? first : (i == tenure ? last : monthly)
        interest = i == tenure ? interest_left.round(2) : (term_charge / tenure).round(2)
        interest_left -= interest
        balance = (balance - amount).round(2)
        due = @f.first_due_on >> (i - 1)
        @rows << Row.new(n: i, due_on: due, amount:, interest:, principal: (amount - interest).round(2), balance: [ balance, 0 ].max,
                         paid_on: @paid[i], status: status(@paid[i], due))
      end
    end

    def status(paid, due)
      return "paid" if paid
      return "overdue" if due < @today

      due.beginning_of_month == @today.beginning_of_month ? "due" : "upcoming"
    end
  end
end
