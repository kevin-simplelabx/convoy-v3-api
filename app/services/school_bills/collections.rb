# Collections of a school (port of finVals): its issued bills, each worked out for today, filtered by billing period
# (of a year), status (Overdue includes part-paid bills past due) and search (number, bill to, code, lines); the counts
# per status and the totals (Billed, Collected, Outstanding, Overdue, Credited) of the bills in the period.
module SchoolBills
  class Collections < ApplicationService
    STATUSES = [ "Due", "Overdue", "Part Paid", "Paid", "Credited" ].freeze

    def initialize(school, year: nil, period_index: nil, status: nil, q: nil, today: Date.current)
      @school = school
      @year = year
      @period = period_index.presence&.to_i
      @status = status.presence
      @q = q.to_s.strip.downcase.presence
      @today = today
    end

    def call
      scope = SchoolBill.issued.where(school: @school)
      scope = scope.where(academic_year: @year, kind: "period", period_index: @period) if @year && @period
      bills = scope.includes(:family, :issued_by, :lines, payments: %i[receipt recorded_by], waivers: :created_by, notes: :created_by)
                   .order(issued_on: :desc, id: :desc).to_a
      policy = Calc.policies([ @school.id ], today: @today)[@school.id]
      all = bills.map { Calc.call(it, policy:, today: @today) }
      shown = all.select { status?(it) && search?(it.bill) }
      { rows: shown, counts: counts(all), kpis: kpis(all) }
    end

    def self.r2(x) = x.to_d.round(2)

    private

    def status?(c) = @status.nil? || c.status == @status || (@status == "Overdue" && c.status == "Part Paid" && c.overdue)

    def search?(b)
      @q.nil? || [ b.number, b.to_name, b.bill_to_code, *b.lines.map(&:description) ].compact.any? { it.downcase.include?(@q) }
    end

    def counts(all) = { "all" => all.size }.merge(STATUSES.index_with { |s| all.count { it.status == s } })

    def kpis(all)
      over = all.select(&:overdue)
      { billed: Collections.r2(all.sum(0.to_d) { it.bill.total + it.debited }), bills: all.size,
        collected: Collections.r2(all.sum(0.to_d, &:paid)),
        outstanding: Collections.r2(all.sum(0.to_d, &:owed)), not_paid: all.count { it.owed > 0.005 },
        overdue: Collections.r2(over.sum(0.to_d, &:owed)), overdue_bills: over.size,
        credited: Collections.r2(all.sum(0.to_d) { it.credited + it.late_waived }) }
    end
  end
end
