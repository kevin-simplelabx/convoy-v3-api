class ClientInvoiceBlueprint < ApplicationBlueprint
  fields :kind, :number, :status, :client_id, :client_site_id, :invoice_id, :trip_id, :bill_to_name, :issued_on, :due_on,
         :period_from, :period_to, :period_label, :subtotal, :gst, :total

  field(:display_status) { |i| i.display_status }
  field(:client_name) { |i| i.client.name }
  field(:balance) { |i| i.invoice? && !i.draft? ? i.balance : nil }

  view :detail do
    fields :bill_to_uen, :bill_to_address, :attention, :po, :terms_days, :gst_on, :gst_rate, :gst_mode, :notes, :reason,
           :issued_at, :voided_at, :created_at
    field(:paid) { |i| i.paid }
    field(:credited) { |i| i.credited }
    field(:lines) do |i|
      i.lines.map do |l|
        { id: l.id, source: l.source, trip_id: l.trip_id, ref: l.ref, description: l.description, details: l.details,
          period_text: l.period_text, quantity: l.quantity, unit_price: l.unit_price, amount: l.amount,
          runs: l.runs.map { |r| { id: r.id, occurrence_id: r.occurrence_id, date: r.occurrence_date, start_time: Clock.hm(r.start_time), trip_label: r.trip_label, amount: r.amount, waived: r.waived } } }
      end
    end
    field(:payments) { |i| i.payments.map { |p| { id: p.id, paid_on: p.paid_on, amount: p.amount, method: p.method, reference: p.reference, by: p.recorded_by&.shown_name } } }
    field(:credit_notes) { |i| i.credit_notes.map { |c| { id: c.id, number: c.number, issued_on: c.issued_on, total: c.total, reason: c.reason, status: c.status } } }
    field(:sends) { |i| i.sends.map { |s| { at: s.created_at, to: s.to_emails, cc: s.cc_emails, by: s.sent_by&.shown_name } } }
    field(:invoice_number) { |i| i.invoice&.number }
  end
end
