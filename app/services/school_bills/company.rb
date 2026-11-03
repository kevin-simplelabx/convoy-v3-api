# Finance › School Bus Collections (port of cfinVals 'cfcol'): the issued School Bus bills of every school the user may
# open (or one), worked out for today — totals (Billed, Collected, Outstanding, Overdue), a line per school, the counts
# per status and the latest 200 bills by status and search (number, bill to, code, school).
module SchoolBills
  class Company < ApplicationService
    LIMIT = 200

    def initialize(schools, status: nil, q: nil, today: Date.current)
      @schools = schools.to_a
      @status = status.presence
      @q = q.to_s.strip.downcase.presence
      @today = today
    end

    def call
      bills = SchoolBill.issued.where(school: @schools).includes(:school, :family, :lines, :waivers, :payments, :notes).to_a
      policies = Calc.policies(@schools.map(&:id), today: @today)
      all = bills.map { Calc.call(it, policy: policies[it.school_id], today: @today) }
      list = all.select { (@status.nil? || it.status == @status) && search?(it.bill) }
                .sort_by { [ it.bill.issued_on, it.bill.number ] }.reverse
      { kpis: totals(all), by_school: @schools.sort_by(&:name).map { |s| totals(all.select { it.bill.school_id == s.id }).merge(school_id: s.id, name: s.name) },
        counts: { "all" => all.size }.merge(Collections::STATUSES.index_with { |st| all.count { it.status == st } }),
        rows: list.first(LIMIT).map { Present.row(it).merge(school_id: it.bill.school_id, school: it.bill.school.name) }, count: list.size }
    end

    private

    def search?(b) = @q.nil? || [ b.number, b.to_name, b.bill_to_code, b.school.name ].compact.any? { it.downcase.include?(@q) }

    def totals(list)
      over = list.select(&:overdue)
      { bills: list.size, billed: (list.sum(0.to_d) { it.bill.total + it.debited }).round(2), collected: list.sum(0.to_d, &:paid).round(2),
        outstanding: list.sum(0.to_d, &:owed).round(2), not_paid: list.count { it.owed > 0.005 }, overdue: over.sum(0.to_d, &:owed).round(2),
        overdue_bills: over.size }
    end
  end
end
