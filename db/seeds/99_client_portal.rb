# Client Portal pages with something to show: Google's draft invoice issued and part paid (Invoices), a School Bus bill
# St. Stephen's School pays as the school, overdue (Invoices, School Bus), and a notice in force on Google's MBC shuttle
# (Home, Notices). Dates follow today.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  google = Client.find_by!(name: "Google Asia Pacific")
  draft = ClientInvoice.where(client: google, kind: "invoice", status: "draft").order(:id).first
  if draft && draft.lines.any?
    ClientInvoices::Edit.new(invoice: draft, user: ops).issue!
    ClientInvoices::Money.new(invoice: draft.reload, user: ops).pay!(amount: (draft.total / 2).round(2), method: "PayNow", reference: "PN-GAP-1")
  end

  sss = Client.find_by!(name: "St. Stephen's School")
  if sss.school && !SchoolBill.exists?(number: "SB-SSS-T4-2026")
    SchoolBill.create!(company_id: sss.company_id, school: sss.school, client: sss, payer: "school", kind: "period", status: "issued",
                       number: "SB-SSS-T4-2026", bill_to: sss.name, period_label: "Term 4 2026", issued_on: Date.current - 40,
                       due_on: Date.current - 10, subtotal: 4800, total: 4800, issued_at: 40.days.ago, issued_by: ops)
  end

  shuttle = Trip.kept.find_by(client: google, kind: "corporate_shuttle")
  if shuttle && !Notice.exists?(trip: shuttle, message: "From Monday the 18:00 run leaves from Tower 2 lobby")
    Notice.create!(company_id: shuttle.company_id, audience: "trip", trip: shuttle, message: "From Monday the 18:00 run leaves from Tower 2 lobby",
                   starts_at: Time.current.beginning_of_day - 1.day, ends_at: Time.current.end_of_day + 7.days, banner: true, push: true, created_by: ops)
  end
end
