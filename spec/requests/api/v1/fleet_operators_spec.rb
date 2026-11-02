require "rails_helper"

# Transport Operators > Managed Operators: payment details with Singapore banks, Routes column, delete rule.
RSpec.describe "Managed operators" do
  let(:company) { create(:company) }
  let!(:banks) do
    dbs = Bank.create!(key: "7171D", code: "7171", name: "DBS Bank Ltd", short_name: "DBS", branch_rule: "pre3")
    dbs.branches.create!(code: "072", name: "DBS Tampines")
    uob = Bank.create!(key: "7375", code: "7375", name: "United Overseas Bank Ltd", short_name: "UOB", branch_rule: "uob")
    uob.branches.create!(code: "001", name: "Main", account_prefix: "101")
    citi = Bank.create!(key: "7214", code: "7214", name: "Citibank NA", short_name: "Citibank", branch_rule: "list")
    %w[001 011].each { |c| citi.branches.create!(code: c, name: "Citi #{c}") }
    { dbs:, uob:, citi: }
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  def save(id: nil, **attrs)
    body = { operator: { name: "Hup Seng", kind: "managed" }.merge(attrs) }
    id ? patch(api_v1_operator_path(id), params: body, as: :json) : post(api_v1_operators_path, params: body, as: :json)
  end

  it "uses the UEN for PayNow and checks its format" do
    save(uen: "199801234d")
    expect(json[:data]).to include(uen: "199801234D", paynow_uen: "199801234D", pays_by: { method: "PayNow UEN", to: "199801234D", warn: false })

    save(name: "Bad", uen: "12345")
    expect(json.dig(:error, :details, :uen)).to eq([ "Uen looks wrong. Examples: 53012345A, 201912345K, T09LL1234A" ])
    save(name: "None")
    expect(json.dig(:error, :details, :paynow_uen)).to eq([ "Paynow uen is needed, or pick Bank Transfer" ])
  end

  it "works out the branch from the account number by the bank's rule" do
    save(payment_method: "bank", bank_id: banks[:dbs].id, account_number: "072-123456-7", account_name: "HUP SENG PTE LTD")
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(bank_code: "7171", branch_code: "072", branch_name: "DBS Tampines", account_number: "0721234567",
                                   pays_by: { method: "Bank Transfer", to: "DBS 0721234567 | HUP SENG PTE LTD", warn: false })
    id = json.dig(:data, :id)

    save(bank_id: banks[:uob].id, account_number: "9991234567", id:)
    expect(json.dig(:error, :details, :account_number)).to eq([ "Account number matches no UOB branch (check the first 3 digits)" ])

    save(bank_id: banks[:citi].id, account_number: "12345678", id:)
    expect(json.dig(:error, :details, :branch_code)).to eq([ "Branch code must be picked" ])
    save(bank_id: banks[:citi].id, account_number: "12345678", branch_code: "011", id:)
    expect(json[:data]).to include(branch_code: "011", bank_name: "Citibank")

    save(account_number: "123", id:)
    expect(json.dig(:error, :details, :account_number)).to eq([ "Account number should be 6 to 14 digits" ])
  end

  it "lists banks and the branch of an account as it is typed" do
    get api_v1_banks_path
    citi = json[:data].find { |b| b[:key] == "7214" }
    expect(citi).to include(pick_branch: true, branches: [ { code: "001", name: "Citi 001" }, { code: "011", name: "Citi 011" } ])
    expect(json[:data].find { |b| b[:key] == "7171D" }).to include(label: "DBS | DBS Bank Ltd (7171)", branches: [])

    get branch_api_v1_bank_path(banks[:dbs]), params: { account_number: "123456789" }
    expect(json[:data]).to include(code: "081", note: "9-digit DBS accounts are POSB accounts, so 081 is used")
    get branch_api_v1_bank_path(banks[:uob]), params: { account_number: "1012345678" }
    expect(json[:data]).to include(code: "001", name: "Main")
  end

  it "keeps the hire costs of an external operator without payment rules" do
    save(kind: "external", name: "Kallang Bus", cost_per_trip: 180, cost_per_day: "650.50", valid_until: "2026-12-31")
    expect(json[:data]).to include(cost_per_trip: "180.0", cost_per_day: "650.5", pays_by: { method: "Not set", to: "Add PayNow / UEN in External Vehicles", warn: true })
  end

  it "counts the School Bus routes and buses of each operator, and keeps an operator with buses" do
    hup = within_tenant(company) do
      hup = create(:operator, name: "Hup Seng")
      bus = create(:vehicle, plate: "PC7475L", operator: hup)
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", calendar: create(:calendar, kind: :school))
      plan = school.plans.create!(name: "Term 4 AM", session: "am", effective_from: Date.new(2026, 10, 1))
      route = plan.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20")
      route.vehicle_changes.create!(vehicle: bus, effective_from: Date.new(2026, 10, 1))
      hup
    end

    get api_v1_operators_path, params: { q: { kind_eq: "managed" } }
    expect(json[:data].first).to include(name: "Hup Seng", routes_count: 1, vehicles_count: 1)

    delete api_v1_operator_path(hup)
    expect(json.dig(:error, :message)).to eq("Remove the 1 vehicle of Hup Seng first")
  end
end
