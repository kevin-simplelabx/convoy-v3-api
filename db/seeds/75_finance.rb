# Finance for SimpleDrive. Settings: GST-registered at 9 % on top, one-person approval (ops and finance approve),
# document branding and where clients pay (DBS account and PayNow UEN).
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  fin = User.find_by!(email: "finance@simpledrive.sg")
  settings = FinanceSetting.current
  if settings.gst_reg_no.blank?
    settings.update!(gst_on: true, gst_rate: 9, gst_mode: "excl", gst_reg_no: "M90012345A", brand_name: "SimpleDrive Pte Ltd",
                     brand_uen: "201912345K", brand_address: "21 Kaki Bukit Ave 1, #04-02, Singapore 417943", brand_phone: "+65 6123 4567",
                     brand_email: "accounts@simpledrive.sg", bank: Bank.find_by(short_name: "DBS"), account_number: "0721234567",
                     account_name: "SIMPLEDRIVE PTE LTD", paynow: "201912345K")
  end
  [ [ ops, true ], [ fin, true ] ].each do |user, approve|
    FinanceApprover.find_or_create_by!(company_id: settings.company_id, user:) { |a| a.assign_attributes(can_prepare: true, can_approve: approve) }
  end
end

# Client Invoices: billing terms for Google; last month invoiced for the first client with runs to bill (issued),
# and a draft for the next one, so Ready to Invoice, Drafts and Unpaid all have rows.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  Client.find_by(name: "Google Asia Pacific")&.update!(payment_terms_days: 30, default_po: "PO-GAP-2026", late_cancel_hours: 24)
  last = Date.current.prev_month.beginning_of_month
  unless ClientInvoice.exists?
    entities = ClientInvoices::Billable.call(month: last).select { |e| (e.bill + e.late).any? }.sort_by(&:name)
    if (first = entities.first)
      inv = ClientInvoices::Draft.call(client: first.client, site: first.site, month: last, user: ops)
      ClientInvoices::Edit.new(invoice: inv, user: ops).issue!
    end
    if (second = entities.second)
      ClientInvoices::Draft.call(client: second.client, site: second.site, month: last, user: ops)
    end
  end
end

# The issued invoice is part paid (half by PayNow) and recorded as emailed.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  inv = ClientInvoice.invoice.issued.order(:id).first
  if inv && inv.payments.none?
    money = ClientInvoices::Money.new(invoice: inv, user: ops)
    money.pay!(paid_on: Date.current, amount: (inv.total / 2).round(2), method: "PayNow", reference: "PAYNOW-0001")
    money.send!(to: [ "accounts@client.example" ])
  end
end

# Operator Payments: a manual deduction, and the ready requests of last month approved into a batch paying next Friday.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  op = Operator.kept.order(:id).first
  if op && !OperatorPayItem.exists?
    OperatorPayItem.create!(operator: op, description: "Late arrival, client complaint", item_on: Date.current.prev_month.end_of_month,
                            amount: -30, created_by: ops)
  end
  unless OperatorPayBatch.exists?
    last = Date.current.prev_month
    ready = OperatorPay::Due.call.select { |i| i.ready && i.item_on.year == last.year && i.item_on.month == last.month }
    friday = Date.current.next_occurring(:friday)
    OperatorPay::Batches.new(user: ops).approve!(refs: ready.map(&:ref), pay_date: friday) if ready.any?
  end
end

# Vehicle Financials: the first own bus on a loan (instalments paid up to last month), the second paid in full,
# the rest with no details.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  buses = Vehicle.kept.own.order(:id).first(2)
  if (bus = buses[0]) && bus.financial.nil?
    start = (Date.current << 14).change(day: 15)
    fin = bus.create_financial!(company_id: bus.company_id, funding: "loan", purchase_price: 125_000, bought_on: start - 30, lender: "Think One Credit Pte Ltd",
                                account_number: "TOC26/0916/117228", loan_amount: 110_000, rate: 3.58, tenure_months: 48, first_due_on: start, updated_by: ops)
    fin.schedule.rows.select { |r| r.due_on < Date.current.beginning_of_month }.each { |r| fin.payments.create!(instalment_no: r.n, paid_on: r.due_on, recorded_by: ops) }
  end
  buses[1]&.then { |b| b.financial || b.create_financial!(company_id: b.company_id, funding: "cash", purchase_price: 68_000, bought_on: Date.current << 30, updated_by: ops) }
end

# Vehicle P&L: a monthly contract revenue and parking on the loan bus, road tax once a year.
with_company("SD") do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  bus = Vehicle.kept.own.order(:id).first
  if bus && bus.finance_entries.none?
    start = (Date.current << 6).beginning_of_month
    bus.finance_entries.create!(company_id: bus.company_id, kind: "revenue", category: "Contract", entry_on: start, amount: 4200, repeats_monthly: true,
                                note: "Factory contract, monthly", created_by: ops)
    bus.finance_entries.create!(company_id: bus.company_id, kind: "cost", category: "Parking and ERP", entry_on: start, amount: 180, repeats_monthly: true, created_by: ops)
    bus.finance_entries.create!(company_id: bus.company_id, kind: "cost", category: "Road Tax", entry_on: start, amount: 1440, created_by: ops)
  end
end
