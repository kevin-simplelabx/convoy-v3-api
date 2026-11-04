require "rails_helper"

# Finance > Client Invoices: Ready to Invoice, late cancellations, drafts, Issue (numbered), Void (runs go back), Invoice Now.
RSpec.describe "Finance client invoices" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      FinanceSetting.current.update!(gst_on: true, gst_rate: 9)
      google = create(:client, name: "Google", uen: "200817984R", billing_address: "70 Pasir Panjang Road")
      trip = create(:trip, client: google, title: "Office Shuttle", days: [ 1, 2, 3, 4, 5 ], end_mode: "never", starts_on: Date.new(2026, 10, 1))
      adhoc = create(:trip, client: google, title: "Airport Run", starts_on: Date.new(2026, 11, 20))
      occ = ->(t, day, **attrs) do
        date = Date.new(2026, t == adhoc ? 11 : 10, day)
        TripOccurrence.create!({ trip: t, client: google, date:, start_time: 480, end_time: 540, starts_at: date.in_time_zone.change(hour: 8),
                                 ends_at: date.in_time_zone.change(hour: 9), kind: "ad_hoc", trip_label: "T#{t.id}-#{day}", price: 120, run_key: "k#{day}" }.merge(attrs))
      end
      { google:, trip:, adhoc:,
        runs: [ occ.(trip, 6), occ.(trip, 7), occ.(trip, 8, price: 0),
                occ.(trip, 9, issue_raised_at: Time.current, issue_reason: "Late"),
                occ.(trip, 12, status: "cancelled", cancelled_at: Date.new(2026, 10, 12).in_time_zone.change(hour: 6), cancelled_by_client: true),
                occ.(trip, 13, status: "cancelled", cancelled_at: Date.new(2026, 10, 10).in_time_zone, cancelled_by_client: true),
                occ.(trip, 14, status: "cancelled", cancelled_at: Date.new(2026, 10, 14).in_time_zone.change(hour: 7)),
                occ.(adhoc, 20, price: 300) ] }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, name: "Marcus Lim", permissions: %w[finance]))
  end

  it "lists what is ready, drafts the month, waives a late cancellation, issues and voids" do
    get ready_api_v1_finance_invoices_path, params: { month: "2026-10" }
    row = json[:data].first
    expect(row).to include(name: "Google", runs: 2, late_cancels: 1, amount: "360.0", drafts_open: 0)
    expect(row[:blocked].map { |b| b[:reason] }).to eq([ "No client price on the trip", "An issue is raised on this run" ])

    post api_v1_finance_invoices_path, params: { client_id: data[:google].id, month: "2026-10" }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    inv = json[:data]
    expect(inv).to include(status: "draft", number: nil, bill_to_name: "Google", terms_days: 30, gst_on: true, subtotal: "360.0", gst: "32.4", total: "392.4")
    expect(inv[:lines].map { |l| [ l[:source], l[:quantity], l[:unit_price], l[:amount] ] })
      .to eq([ [ "trip", "2.0", "120.0", "240.0" ], [ "late_cancel", "1.0", "120.0", "120.0" ] ])

    late_run = inv[:lines].second[:runs].first[:id]
    patch api_v1_finance_invoice_path(inv[:id]), params: { invoice: { waived_run_ids: [ late_run ], po: "PO-77",
                                                                      manual_lines: [ { description: "ERP charges", amount: 15 } ] } }, as: :json
    expect(json[:data]).to include(po: "PO-77", subtotal: "255.0", total: "277.95")

    get ready_api_v1_finance_invoices_path, params: { month: "2026-10" }
    expect(json[:data].first).to include(runs: 0, late_cancels: 0, drafts_open: 1)

    post issue_api_v1_finance_invoice_path(inv[:id])
    expect(json[:data]).to include(status: "issued", number: "INV-2026-000001", issued_on: "2026-11-02", due_on: "2026-12-02", display_status: "issued", balance: "277.95")
    patch api_v1_finance_invoice_path(inv[:id]), params: { invoice: { po: "X" } }, as: :json
    expect(json.dig(:error, :message)).to eq("Only drafts can be changed")

    post void_api_v1_finance_invoice_path(inv[:id])
    expect(json[:data]).to include(status: "void")
    get ready_api_v1_finance_invoices_path, params: { month: "2026-10" }
    expect(json[:data].first).to include(runs: 2, late_cancels: 1)
  end

  it "invoices a one-off trip before it runs" do
    get ad_hoc_api_v1_finance_invoices_path
    expect(json[:data].first).to include(title: "Airport Run", amount: "300.0", done: false)

    post api_v1_finance_invoices_path, params: { trip_id: data[:adhoc].id }, as: :json
    expect(json[:data]).to include(trip_id: data[:adhoc].id, total: "327.0", period_from: "2026-11-20")
    get ad_hoc_api_v1_finance_invoices_path
    expect(json[:data]).to eq([])
  end

  it "keeps billing details on the client" do
    patch api_v1_finance_billing_path(data[:google]), params: { billing: { payment_terms_days: 14, late_cancel_hours: 48,
                                                                          billing_contacts: [ { name: "AP", email: "ap@google.com" } ] } }, as: :json
    expect(json[:data]).to include(terms_days: 14, late_cancel_hours: 48, billing_contacts: [ hash_including(email: "ap@google.com", send_as: "to") ])

    # Billing Name: the legal name on invoices (blank = the client's name).
    patch api_v1_finance_billing_path(data[:google]), params: { billing: { billing_name: "Google Asia Pacific Pte. Ltd." } }, as: :json
    expect(json[:data]).to include(name: "Google", billing_name: "Google Asia Pacific Pte. Ltd.", bill_name: "Google Asia Pacific Pte. Ltd.")
    post api_v1_finance_invoices_path, params: { client_id: data[:google].id, month: "2026-10" }, as: :json
    expect(json.dig(:data, :bill_to_name)).to eq("Google Asia Pacific Pte. Ltd.")
  end

  it "records payments and a credit note, and reports owed, aging and the statement" do
    post api_v1_finance_invoices_path, params: { client_id: data[:google].id, month: "2026-10" }, as: :json
    id = json.dig(:data, :id)
    post payments_api_v1_finance_invoice_path(id), params: { amount: 10, method: "PayNow" }, as: :json
    expect(json.dig(:error, :message)).to eq("Only an issued invoice can take this")
    post issue_api_v1_finance_invoice_path(id) # 392.40 due 2 Dec

    post payments_api_v1_finance_invoice_path(id), params: { amount: 500, method: "PayNow" }, as: :json
    expect(json.dig(:error, :message)).to eq("More than the balance of S$392.40")
    post payments_api_v1_finance_invoice_path(id), params: { paid_on: "2026-11-02", amount: 200, method: "PayNow", reference: "TX1" }, as: :json
    post credit_note_api_v1_finance_invoice_path(id), params: { amount: 92.4, reason: "Late bus on 6 Oct" }, as: :json
    expect(json[:data]).to include(paid: "200.0", credited: "92.4", balance: "100.0", display_status: "partly_paid")
    expect(json.dig(:data, :credit_notes, 0)).to include(number: "CN-2026-000001", total: "92.4")

    post send_api_v1_finance_invoice_path(id), as: :json
    expect(json.dig(:error, :message)).to eq("Add who the invoice goes To in Billing Details")
    post send_api_v1_finance_invoice_path(id), params: { to: [ "ap@google.com" ] }, as: :json
    expect(json.dig(:data, :sends, 0)).to include(to: [ "ap@google.com" ], cc: [])

    get summary_api_v1_finance_invoices_path
    expect(json[:data]).to include(owed: "100.0", overdue: "0.0", invoiced: "392.4", collected: "200.0")
    expect(json.dig(:data, :aging, 0)).to include(key: "current", amount: "100.0", count: 1)

    get statement_api_v1_finance_invoices_path, params: { client_id: data[:google].id }
    expect(json.dig(:data, :rows).map { |r| [ r[:type], r[:balance] ] }).to eq([ [ "invoice", "392.4" ], [ "payment", "192.4" ], [ "credit_note", "100.0" ] ])

    get api_v1_finance_invoices_path, params: { tab: "credit_notes" }
    expect(json[:meta][:counts]).to include(unpaid: 1, credit_notes: 1)
  end
end
