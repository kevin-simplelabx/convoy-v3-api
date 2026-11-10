# The Family Bills card of Collections (port of fiColVals) for one billing period of a year: who pays (parents get one
# bill per family; a school paying per rider or per bus gets one bill, to its Managed Client), the periods to pick, the
# last draft (when, by whom, what it left out) or when Convoy will draft, and the period's bills, drafts first.
module SchoolBills
  class Board < ApplicationService
    def initialize(year, index: nil, q: nil, today: Date.current)
      @year = year
      @school = year.school
      @index = index
      @q = q.to_s.strip.downcase.presence
      @today = today
    end

    def call
      table = @year.fare_table
      return { on: false, error: "Lock the Bus Fares for this year first" } unless table&.locked?

      periods = FareTables.periods(@year, table)
      months = FareTables.bill_months(@year, table)
      i = @index.presence&.to_i&.clamp(0, periods.size - 1) || SchoolBills.current_index(@year, @today)
      start = table.cycle == "month" ? months[i] : (periods[i][:starts_on] || months[i])
      settings = FinanceSetting.current
      due = SchoolBills.due_on(@school.policy_versions.in_use_on(@today), start)
      run = SchoolBillRun.includes(:drafted_by).find_by(school: @school, academic_year: @year, period_index: i)
      bills = SchoolBill.where(school: @school, academic_year: @year, kind: "period", period_index: i).includes(:family, :lines).to_a
      shown = bills.select { @q.nil? || [ it.to_name, it.bill_to_code, *it.lines.filter_map(&:child_name) ].compact.any? { |v| v.downcase.include?(@q) } }
                   .sort_by { [ it.issued? ? 1 : 0, it.to_name.to_s ] }
      payer = { "parents" => "family", "school" => "school", "bus" => "bus" }[table.payer]
      client = @school.client
      { on: true, payer:, academic_year_id: @year.id, period_index: i,
        periods: periods.each_index.map { |j| { index: j, label: period_label(table, periods, months, j), month: months[j] } },
        due_on: due, draft_on: due - settings.school_bill_draft_days,
        bill_to: payer == "family" ? nil : { managed_client: client && { id: client.id, name: client.name }, linked: client.present? },
        run: run && { drafted_at: run.drafted_at, by: run.drafted_by&.name || "Convoy", auto: run.auto, label: run.label, due_on: run.due_on,
                      skipped: run.skipped, unlinked: run.unlinked },
        counts: { bills: bills.size, drafts: bills.count(&:draft?), issued: bills.count(&:issued?), amount: bills.sum(0.to_d, &:total).round(2) },
        can_issue: bills.any?(&:draft?) && (payer == "family" || client.present?),
        settings: { draft_days: settings.school_bill_draft_days, start_rule: settings.school_bill_start_rule },
        rows: shown.first(150).map { row(it) }, more: [ shown.size - 150, 0 ].max }
    end

    private

    def period_label(table, periods, months, j)
      m = "#{FareTables::MONTHS[months[j].month - 1]} #{months[j].year}"
      table.cycle == "month" ? m : "#{periods[j][:label]} | billed #{m}"
    end

    def row(b)
      kids = b.lines.reject(&:credit_note_id).filter_map(&:child_name).uniq
      { id: b.id, status: b.status, number: b.number, family_id: b.family_id, bill_to: b.to_name, bill_to_code: b.bill_to_code, children: kids,
        amount: b.draft? ? b.lines.sum(0.to_d, &:amount) : b.total, part_charges: b.lines.to_a.count { it.note.present? },
        lines: b.lines.map { it.slice(:rid, :child_name, :description, :note, :amount) } }
    end
  end
end
