# How School Finance shows bills: a Collections row (with what it comes to today) and the full bill with its lines, GST
# and history (payments, credit and debit notes, waivers), newest first.
module SchoolBills
  module Present
    module_function

    def row(c)
      b = c.bill
      kids = b.lines.reject(&:credit_note_id).filter_map(&:child_name).uniq
      { id: b.id, number: b.number, kind: b.kind, payer: b.payer, family_id: b.family_id, bill_to: b.to_name, bill_to_code: b.bill_to_code,
        bill_to_email: b.bill_to_email, children: kids, lines_count: b.lines.to_a.size, period: b.period_label, academic_year_id: b.academic_year_id,
        period_index: b.period_index, issued_on: b.issued_on, due_on: b.due_on, total: b.total, paid: c.paid, late_fee: c.late,
        late_waived: c.late_waived, credited: c.credited, debited: c.debited, owed: c.owed, overdue: c.overdue, days_overdue: c.days_overdue,
        status: c.status, tone: c.tone }
    end

    def detail(c)
      b = c.bill
      lines = b.lines.map { it.slice(:id, :rid, :child_name, :description, :note, :amount).merge(credit_note: it.credit_note_id.present?) }
      row(c).merge(
        lines:, subtotal: b.subtotal, gst: b.gst_rate.positive? ? { rate: b.gst_rate, amount: b.gst_amount, mode: FinanceSetting.current.gst_mode } : nil,
        late_fee_raw: c.late_raw, net: c.net, drafted_at: b.drafted_at, issued_at: b.issued_at, issued_by: b.issued_by&.name,
        history: history(b),
        can: { pay: b.issued? && c.owed > 0.005, waive_late: b.issued? && c.late > 0.005, notes: b.issued? }
      )
    end

    def history(b)
      pays = b.payments.reject(&:voided?).map do |p|
        { kind: "payment", on: p.paid_on, amount: p.amount, method: p.method, reference: p.reference, receipt: p.receipt&.number, source: p.source, by: p.recorded_by&.name }
      end
      notes = b.notes.reject(&:voided?).map do |d|
        { kind: d.doc_type, on: d.issued_on, amount: d.total, number: d.number, credit_use: d.credit_use, description: d.description, reason: d.reason, by: d.created_by&.name }
      end
      waivers = b.waivers.map { { kind: "waiver", waiver: it.kind, on: it.created_at.to_date, amount: it.amount, reason: it.reason, by: it.created_by&.name } }
      (pays + notes + waivers).sort_by { it[:on] }.reverse
    end
  end
end
