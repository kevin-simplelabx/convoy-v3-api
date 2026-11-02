require "rails_helper"

# Finance > Vehicle Financials: funding status, the loan schedule (flat-rate term charge), instalments paid, the lender's
# schedule read by Claude (plate check).
RSpec.describe "Finance vehicle financials" do
  let(:company) { create(:company) }
  let!(:bus) { within_tenant(company) { create(:vehicle, plate: "PC7475L", seats: 23) } }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[vehfin]))
  end

  def save(**attrs) = patch(api_v1_finance_vehicle_path(bus), params: { financial: attrs }, as: :json)

  it "works out the loan schedule and what is owed" do
    get api_v1_finance_vehicles_path
    expect(json[:data].first).to include(plate: "PC7475L", status: "no_details")

    save(funding: "loan", loan_amount: 100_000)
    expect(json.dig(:error, :details).keys).to include(:tenure_months, :first_due_on)

    save(funding: "loan", purchase_price: 125_000, loan_amount: 100_000, rate: 3, tenure_months: 48, first_due_on: "2026-09-15", lender: "Think One Credit")
    expect(response).to have_http_status(:ok), json.inspect
    expect(json.dig(:data, :schedule)).to include(term_charge: "12000.0", total: "112000.0", monthly: "2334.0", last: "2302.0", down: "25000.0")
    expect(json[:data]).to include(status: "overdue", lender: "Think One Credit")
    expect(json.dig(:data, :rows).first(3).map { |r| [ r[:n], r[:due_on], r[:status] ] })
      .to eq([ [ 1, "2026-09-15", "overdue" ], [ 2, "2026-10-15", "overdue" ], [ 3, "2026-11-15", "due" ] ])

    post api_v1_finance_vehicle_instalments_path(bus), params: { numbers: [ 1, 2 ] }, as: :json
    expect(json[:data]).to include(status: "loan_active", owed: (112_000 - 4668).to_d.to_s)
    expect(json.dig(:data, :schedule)).to include(paid_count: 2, interest_paid: "500.0")

    get api_v1_finance_vehicles_path
    expect(json[:meta]).to include(purchase_cost: "125000.0", monthly: "2334.0", due_this_month: "2334.0")
  end

  it "fills empty fields from the lender's schedule and checks the plate" do
    read = within_tenant(company) do
      DocumentRead.new(kind: "vehicle_loan_schedule", input_text: "schedule", status: "done",
                       result: { plate: "PD1234A", lender: "Hong Leong Finance", loan_amount: 90_000, tenure_months: 60,
                                 first_due_on: "2026-01-05", paid: [ { n: 1, paid_on: "2026-01-05" } ] }).tap { |r| r.save!(validate: false) }
    end
    patch api_v1_finance_vehicle_path(bus), params: { financial: { purchase_price: 110_000 }, document_read_id: read.id }, as: :json
    expect(json.dig(:error, :message)).to eq("This schedule is for PD1234A, not PC7475L. Use Anyway or Remove File first")

    patch api_v1_finance_vehicle_path(bus), params: { financial: { purchase_price: 110_000 }, document_read_id: read.id, use_anyway: true }, as: :json
    expect(json.dig(:data, :financial)).to include(lender: "Hong Leong Finance", loan_amount: "90000.0", purchase_price: "110000.0")
    expect(json.dig(:data, :schedule, :paid_count)).to eq(1)
  end
end
