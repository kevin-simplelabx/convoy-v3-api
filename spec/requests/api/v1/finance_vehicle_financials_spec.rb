require "rails_helper"

# Finance > Vehicle Financials: funding status, the loan schedule (flat-rate term charge), instalments paid, the lender's
# schedule read by Claude (plate check).
RSpec.describe "Finance vehicle financials" do
  let(:company) { create(:company) }
  let!(:bus) { within_tenant(company) { create(:vehicle, plate: "PC7475L", seats: 23) } }

  let(:user) { create(:user, company:, name: "Mei Ling", permissions: %w[vehfin]) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  def save(**attrs) = patch(api_v1_finance_vehicle_path(bus), params: { financial: attrs }, as: :json)

  it "works out the loan schedule and what is owed" do
    get api_v1_finance_vehicles_path
    expect(json[:data].first).to include(plate: "PC7475L", status: "no_details", due_this_month: "0.0") # a decimal like the rows with a loan

    save(funding: "loan", loan_amount: 100_000)
    expect(json.dig(:error, :details).keys).to include(:tenure_months, :first_due_on)

    save(funding: "loan", purchase_price: 125_000, loan_amount: 100_000, rate: 3, tenure_months: 48, first_due_on: "2026-09-15", lender: "Think One Credit")
    expect(response).to have_http_status(:ok), json.inspect
    expect(json.dig(:data, :schedule)).to include(term_charge: "12000.0", total: "112000.0", monthly: "2334.0", last: "2302.0", down: "25000.0")
    expect(json[:data]).to include(status: "overdue", lender: "Think One Credit")
    expect(json.dig(:data, :rows).first(3).map { |r| [ r[:n], r[:due_on], r[:status] ] })
      .to eq([ [ 1, "2026-09-15", "overdue" ], [ 2, "2026-10-15", "overdue" ], [ 3, "2026-11-15", "due" ] ])

    post api_v1_finance_vehicle_instalments_path(bus), params: { numbers: [ 1, 2 ] }, as: :json
    expect(json[:data]).to include(status: "loan_active", owed: (112_000 - 4668).to_d.to_s, next_due: { n: 3, due_on: "2026-11-15", amount: "2334.0", of: 48 })
    expect(json.dig(:data, :schedule)).to include(paid_count: 2, interest_paid: "500.0")
    expect(json.dig(:data, :rows).first(3).map { |r| r.values_at(:paid_on, :paid_by) }) # each paid on its due date
      .to eq([ [ "2026-09-15", "Mei Ling" ], [ "2026-10-15", "Mei Ling" ], [ nil, nil ] ])
    post api_v1_finance_vehicle_instalments_path(bus), params: { numbers: [ 4 ] }, as: :json # not due yet: today
    expect(json.dig(:data, :rows, 3, :paid_on)).to eq("2026-11-02")
    post api_v1_finance_vehicle_instalments_path(bus), params: { numbers: [ 4 ], paid: false }, as: :json

    get api_v1_finance_vehicles_path
    expect(json[:meta]).to include(purchase_cost: "125000.0", monthly: "2334.0", due_this_month: "2334.0")
  end

  def loan_read(**attrs)
    within_tenant(company) do
      DocumentRead.new({ kind: "vehicle_loan_schedule", input_text: "schedule", status: "done", user:, result: { plate: "PC7475L" } }.merge(attrs))
                  .tap { |r| r.save!(validate: false) }
    end
  end

  it "only takes a finished loan schedule read the user started" do
    other = create(:user, company:, permissions: %w[vehfin])
    patch api_v1_finance_vehicle_path(bus), params: { financial: { purchase_price: 1 }, document_read_id: loan_read(user: other).id }, as: :json
    expect(response).to have_http_status(:not_found)
    patch api_v1_finance_vehicle_path(bus), params: { financial: { purchase_price: 1 }, document_read_id: loan_read(kind: "fuel_receipt").id }, as: :json
    expect(json.dig(:error, :message)).to eq("That read was for a fuel receipt")
    patch api_v1_finance_vehicle_path(bus), params: { financial: { purchase_price: 1 }, document_read_id: loan_read(status: "pending").id }, as: :json
    expect(json.dig(:error, :message)).to eq("The schedule is still being read")
  end

  it "fills empty fields from the lender's schedule and checks the plate" do
    read = within_tenant(company) do
      DocumentRead.new(kind: "vehicle_loan_schedule", input_text: "schedule", status: "done", user:,
                       result: { plate: "PD1234A", lender: "Hong Leong Finance", loan_amount: 90_000, tenure_months: 60,
                                 first_due_on: "2026-01-05", paid: [ { n: 1, paid_on: "2026-01-05" } ] }).tap { |r| r.save!(validate: false) }
    end
    patch api_v1_finance_vehicle_path(bus), params: { financial: { purchase_price: 110_000 }, document_read_id: read.id }, as: :json
    expect(json.dig(:error, :message)).to eq("This schedule is for PD1234A, not PC7475L. Use Anyway or Remove File first")

    patch api_v1_finance_vehicle_path(bus), params: { document_read_id: read.id, use_anyway: true }, as: :json # a read alone, from the list
    expect(json.dig(:data, :financial)).to include(lender: "Hong Leong Finance", loan_amount: "90000.0")
    expect(json.dig(:data, :schedule, :paid_count)).to eq(1)
    patch api_v1_finance_vehicle_path(bus), params: { financial: { schedule_file: fixture_file_upload("sample.pdf", "application/pdf") } }
    expect(json.dig(:data, :financial, :schedule_file)).to be_present

    patch api_v1_finance_vehicle_path(bus), params: { financial: { remove_schedule_file: true } }, as: :json # Remove File
    expect(json.dig(:data, :financial, :schedule_file)).to be_nil
    expect(json.dig(:data, :schedule, :paid_count)).to eq(1)
    expect(within_tenant(company) { bus.reload.financial.document_read_id }).to be_nil
  end
end
