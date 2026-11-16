require "rails_helper"

# Convoy App › Fees (Phase 5): Billing Contact only (403 for another adult), the Family's own bills (another Family's or
# company's is a 404), the invoice with the school's methods and admin fee, and Pay: simulated as collected at once, recorded
# in OS as an "app" payment with a receipt, a registration fee bill marks the request's fee paid and a first invoice makes it
# Active.
RSpec.describe "Convoy App fees" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:staff) { create(:user, company:, permissions: %w[plans]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", postal: "455789", lat: 1.3138, lng: 103.9283)
      %w[P1 P2 P3 P4 P5 P6].each_with_index { |n, i| school.levels.create!(name: n, position: i, final: n == "P6") }
      year = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      year.terms.first.update!(starts_on: "2027-01-04", ends_on: "2027-05-28")
      year.terms.second.update!(starts_on: "2027-06-28", ends_on: "2027-11-19")
      SchoolSetup.lock!(school:, year:, section: :calendar, user: staff)
      FareTables::Save.call(year, { payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal",
                                    one_way: { type: "pct", value: 60 }, tiers: [ { max_km: 3, fare: 1680 }, { max_km: 6, fare: 1920 }, { fare: 2400 } ],
                                    small: { on: false }, express: { on: false }, cca: { on: false } }, user: staff)
      year.create_registration!(school:, status: "scheduled", renew_from: "2026-10-01", renew_to: "2026-10-31", general_from: "2026-11-01",
                                general_to: "2027-08-31", service_starts_on: "2027-01-04")
      SchoolPolicyVersion.create!(school:, version: 1, effective_on: "2026-01-01", registration_fee: 50, address_notice_days: 14, address_max_days: 90)
      SchoolPaymentMethod.create!(school:, bank_on: true, paynow_on: true, card_on: true, card_fee_kind: "pct", card_fee: 2, paynow_fee_kind: "fixed", paynow_fee: 0.5)
      FinanceSetting.current.update!(account_name: "SimpleDrive Pte Ltd", account_number: "0039123456", paynow: "201812345K")
      { school:, year: }
    end
  end
  let!(:rachel) { app_user(mobile: "9188 2045", name: %w[Rachel Tan]) }
  let!(:david) { app_user(mobile: "9177 3301", name: %w[David Tan]) }
  def token = @token || rachel[1]
  let!(:home) do
    h = Household.create!(name: "Tan Family", postal: "460412", block: "412", street: "Bedok North Ave 2", floor: "08", unit: "123", lat: 1.3236, lng: 103.93,
                          created_by: rachel[0])
    h.members.create!(app_account: rachel[0], status: :active, admin: true, billing_contact: true, relationship: "Mother", invited_via: :creator, joined_at: 1.day.ago)
    h.members.create!(app_account: david[0], status: :active, relationship: "Father", invited_via: :manual, joined_at: 1.day.ago)
    h
  end
  let!(:ethan) { home.dependants.create!(name: "Ethan Tan", birth_date: "2017-03-14", level: "P4", school_id: f[:school].id, school_name: "St. Stephen's School") }
  let!(:lucas) { home.dependants.create!(name: "Lucas Tan", birth_date: "2020-08-02", level: "P1", school_id: f[:school].id, school_name: "St. Stephen's School") }

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  def api(verb, path, token: self.token, **params)
    return get(path, params:, headers: app_as(token)) if verb == :get

    public_send(verb, path, params:, headers: app_as(token), as: :json)
  end

  def tenant(&) = within_tenant(company, &)

  def apply(*kids)
    api(:post, apply_api_v1_convoy_app_school_path, application: { school_id: f[:school].id, agree: true, children: kids })
    json[:data]
  end

  def child(dep) = { dependant_id: dep.id, level: "P5", service: "both", start_when: "first" }

  def pay(bill, method) = api(:post, api_v1_convoy_app_fee_invoice_pay_path(bill), method:)

  it "keeps Fees to the Billing Contact and to the Family's own bills" do
    apply(child(lucas))
    bill = tenant { BusRequest.sole.registration_bill }

    api(:get, api_v1_convoy_app_fees_path, token: david[1])
    expect(response).to have_http_status(:forbidden)
    expect(json[:error]).to include(code: "billing_only")
    api(:get, api_v1_convoy_app_fee_invoice_path(bill), token: david[1])
    expect(response).to have_http_status(:forbidden)
    api(:post, api_v1_convoy_app_fee_invoice_pay_path(bill), token: david[1], method: "card")
    expect(response).to have_http_status(:forbidden)
    expect(tenant { bill.reload.paid? }).to be(false)

    # Another Family's bill at the same school, and a bill at another company: both 404, never listed
    other = tenant do
      fam = f[:school].families.create!(code: "FAM-0099", name: "LIM Family", name_mode: "custom")
      SchoolBill.create!(school: f[:school], family: fam, kind: "period", status: "issued", number: "INV-2026-000999", bill_to: "LIM Family", issued_on: "2026-11-01",
                         due_on: "2026-11-30", period_label: "Term 4", subtotal: 100, total: 100)
    end
    foreign = within_tenant(create(:company)) do
      s = School.create!(name: "Other School")
      SchoolBill.create!(school: s, kind: "period", status: "issued", number: "INV-2026-000001", issued_on: "2026-11-01", due_on: "2026-11-30", period_label: "Term 4", subtotal: 100, total: 100)
    end
    [ other, foreign ].each do |b|
      api(:get, api_v1_convoy_app_fee_invoice_path(b))
      expect(response).to have_http_status(:not_found)
      pay(b, "card")
      expect(response).to have_http_status(:not_found)
    end
    api(:get, api_v1_convoy_app_fees_path)
    expect(json.dig(:data, :invoices).pluck(:id)).to eq([ bill.id ])
  end

  it "pays the registration fee with the card's admin fee, simulated as collected at once" do
    apply(child(lucas))
    req = tenant { BusRequest.sole }
    bill = tenant { req.registration_bill }

    api(:get, api_v1_convoy_app_fees_path)
    d = json[:data]
    expect(d[:outstanding]).to include(total: "50.0", count: 1, pay_first_id: bill.id)
    expect(d[:invoices].sole).to include(number: bill.number, period: "Registration · AY2027", owed: "50.0", can_pay: true, status: { label: "Due", tone: "info" })
    expect(d[:payments]).to eq([])

    api(:get, api_v1_convoy_app_fee_invoice_path(bill))
    inv = json[:data]
    expect(inv[:methods].map { it.slice(:key, :fee_text, :admin_fee, :total) }).to eq(
      [ { key: "bank", fee_text: "No fee", admin_fee: "0.0", total: "50.0" }, { key: "paynow", fee_text: "+S$0.50 admin fee", admin_fee: "0.5", total: "50.5" },
        { key: "card", fee_text: "+2% admin fee", admin_fee: "1.0", total: "51.0" } ]
    )
    expect(inv[:pay_to]).to include(account_number: "0039123456", paynow: "201812345K", reference: bill.number, amount: "50.0")
    expect(inv[:billed_to]).to include(family: "Tan Family", contact: "Rachel Tan")
    expect(inv[:lines].sole).to include(child: "Lucas Tan", amount: "50.0")

    pay(bill, "cheque")
    expect(json.dig(:error, :message)).to eq("Pick how to pay")

    pay(bill, "card")
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(owed: "0.0", can_pay: false, methods: [], pay_to: nil, status: { label: "Paid", tone: "success" })
    expect(json[:data][:payment]).to include(method: "Card", amount: "50.0", admin_fee: "1.0", paid_on: "2026-11-02")
    expect(json[:data][:payment][:receipt_number]).to start_with("RCP")

    # The OS bill is paid, with an app payment and a receipt, and the request's fee is marked paid
    pay_row = tenant { bill.reload.payments.sole }
    expect(pay_row).to have_attributes(source: "app", method: "Card", amount: 50, admin_fee: 1, recorded_by_id: nil)
    expect(pay_row.reference).to start_with("SIM-")
    expect(tenant { [ bill.paid?, req.reload.fee_paid ] }).to eq([ true, true ])

    api(:get, api_v1_convoy_app_fees_path)
    expect(json.dig(:data, :outstanding)).to include(total: "0.0", count: 0)
    expect(json.dig(:data, :payments).sole).to include(amount: "50.0", method: "Card", number: bill.number)
    api(:get, api_v1_convoy_app_school_path)
    expect(json.dig(:data, :actions, :fees)).to eq(due: 0)

    pay(bill, "card")
    expect(json[:error]).to include(code: "already_paid", message: "This invoice is already paid")
    expect(tenant { bill.reload.payments.count }).to eq(1)
  end

  it "pays a period bill with its late fee, lists payments and blocks Delete Family while it is owed" do
    bill = tenant do
      fam = f[:school].families.create!(code: "FAM-0001", name: "TAN Family", name_mode: "custom", household_id: home.id)
      SchoolPolicyVersion.find_by!(school: f[:school]).update!(late_type: "flat", late_flat: 10, late_grace_days: 0)
      b = SchoolBill.create!(school: f[:school], family: fam, kind: "period", status: "issued", number: "INV-2026-000050", bill_to: "TAN Family", issued_on: "2026-10-01",
                             due_on: "2026-10-15", period_label: "Term 4 | Sep 2026", subtotal: 420, total: 420)
      b.lines.create!(child_name: "Ethan Tan", description: "Ethan Tan | 0 to 3 km | 2-way", amount: 420)
      b
    end
    api(:get, api_v1_convoy_app_fees_path)
    expect(json.dig(:data, :invoices).sole).to include(owed: "430.0", status: { label: "Overdue", tone: "danger" })
    api(:get, api_v1_convoy_app_school_path)
    expect(json.dig(:data, :actions, :fees)).to eq(due: 1)
    api(:delete, api_v1_convoy_app_household_path)
    expect(json.dig(:error, :details, :reasons).pluck(:label)).to include("INV-2026-000050 is not paid")

    api(:get, api_v1_convoy_app_fee_invoice_path(bill))
    expect(json[:data]).to include(total: "420.0", late_fee: "10.0", owed: "430.0")
    pay(bill, "paynow")
    expect(json[:data][:payment]).to include(amount: "430.0", admin_fee: "0.5", method: "PayNow")
    expect(tenant { SchoolBills::Calc.call(bill.reload, policy: nil).status }).to eq("Paid")
    api(:get, api_v1_convoy_app_fees_path)
    expect(json.dig(:data, :payments).sole).to include(amount: "430.0", admin_fee: "0.5")
  end

  it "makes the request Active when its first invoice is paid" do
    apply(child(ethan))
    req = tenant { BusRequest.sole }
    pay(tenant { req.registration_bill }, "bank")
    tenant { BusRequests::Accept.call([ req.reload ], user: staff, quote: { amount: 840, start_on: "2027-01-04" }) }
    first = tenant { req.reload.first_bill }

    api(:get, api_v1_convoy_app_school_path)
    expect(json.dig(:data, :children).first[:action]).to include(kind: "first_invoice", bill_id: first.id)
    expect(json.dig(:data, :children).first[:badge]).to include(label: "Accepted")
    api(:get, api_v1_convoy_app_fees_path)
    expect(json.dig(:data, :outstanding)).to include(count: 1, pay_first_id: first.id)

    pay(first, "paynow")
    expect(response).to have_http_status(:ok), json.inspect
    tenant do
      expect(req.reload.status).to eq("Active")
      expect(first.reload.payments.sole).to have_attributes(source: "app", method: "PayNow", admin_fee: 0.5)
      expect(req.events.pluck(:text)).to include("First invoice paid by PayNow. Service is active")
      expect(req.events.find_by(text: "First invoice paid by PayNow. Service is active").by_name).to eq("Rachel Tan")
    end
  end
end
