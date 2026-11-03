# Billing differences (port of the diffs in finVals): for every billing period of a year with issued bills, what each
# issued bill would come to now (riders and fares today, from SchoolBills::Draft) against what it billed plus the debit
# notes and less the credit notes since. A gap suggests a debit note (more now) or a credit note (less now).
module SchoolBills
  class Differences < ApplicationService
    def initialize(year)
      @year = year
    end

    def call
      bills = SchoolBill.issued.where(academic_year: @year, kind: "period").includes(:family, :lines, :notes).to_a
      incl = FinanceSetting.current.gst_incl?
      bills.group_by(&:period_index).flat_map do |index, list|
        d = Draft.call(@year, index)
        next [] if d[:error]

        list.filter_map do |b|
          o = d[:bills].find { b.payer == "school" ? it[:payer] == "school" : it[:family]&.id == b.family_id }
          now = o ? o[:amount] : 0.to_d
          was = b.lines.reject(&:credit_note_id).sum(&:amount)
          adj = b.notes.reject(&:voided?).sum { |n| (n.debit_note? ? 1 : -1) * (incl ? n.total : n.subtotal) }
          gap = (now - was - adj).round(2)
          next if gap.abs <= 0.005

          n = o ? o[:lines].size : 0
          { bill_id: b.id, number: b.number, bill_to: b.to_name, period: b.period_label, was: (was + adj).round(2), now:, gap:,
            suggest: { doc_type: gap.positive? ? "dn" : "cn", description: "Fare change: #{o ? "#{n} rider#{'s' unless n == 1} now" : 'no riders now'}",
                       amount: gap.abs, reason: "Riders or fares changed after the bill was raised", credit_use: "reduce" } }
        end
      end
    end
  end
end
