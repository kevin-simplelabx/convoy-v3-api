require "rails_helper"

# Vehicle Financials > profit and loss of a month worked out by hand, on the profit and the cash basis; manual entries,
# cost spikes and what is due.
RSpec.describe "Finance vehicle P&L" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      plan = PayRatePlan.create!(name: "Flat")
      PayScheme.create!(name: "Basic", rate_plan: plan, basic_salary: 500, is_default: true)
      bus = create(:vehicle, plate: "PC7475L", seats: 23, road_tax_expires_on: Date.new(2026, 12, 1))
      eric = create(:driver, name: "Eric Pang")
      bus.driver_schedules.create!(driver: eric, starts_on: Date.new(2026, 9, 1))
      trip = create(:trip, title: "Charter")
      [ 6, 7 ].each do |day|
        date = Date.new(2026, 10, day)
        TripOccurrence.create!(trip:, date:, start_time: 480, end_time: 540, starts_at: date.in_time_zone.change(hour: 8), ends_at: date.in_time_zone.change(hour: 9),
                               kind: "ad_hoc", trip_label: "T#{day}", vehicle: bus, price: 100, run_key: "k#{day}", status: "completed")
      end
      FuelEntry.create!(vehicle: bus, date: Date.new(2026, 10, 10), kind: "diesel", quantity: 20, cost: 50)
      VehicleInsurancePolicy.create!(vehicle: bus, insurer: "Income", starts_on: Date.new(2026, 1, 1), ends_on: Date.new(2026, 12, 31), premium: 1200)
      bus.create_financial!(company_id: company.id, funding: "cash", purchase_price: 120_000, bought_on: Date.new(2026, 1, 10))
      { bus: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[vehfin]))
  end

  it "adds up revenue and costs of a month on both bases" do
    post api_v1_finance_vehicle_entries_path(data[:bus]), params: { entry: { kind: "cost", category: "Parking and ERP", entry_on: "2026-09-05", amount: 30, repeats_monthly: true } }, as: :json
    expect(response).to have_http_status(:created)
    post api_v1_finance_vehicle_entries_path(data[:bus]), params: { entry: { kind: "cost", category: "School Bus", entry_on: "2026-09-05", amount: 30 } }, as: :json
    expect(json.dig(:error, :details, :category)).to eq([ "Category is not a cost category" ])

    get api_v1_finance_vehicle_pl_path(data[:bus]), params: { month: "2026-10", basis: "profit" }
    cats = json.dig(:data, :categories).to_h { |c| [ c[:category], c[:amount] ] }
    expect(cats).to eq("Ad Hoc / Charter (auto)" => "200.0", "Depreciation" => "1000.0", "Driver Salary (auto)" => "500.0",
                       "Insurance Premium (auto)" => "100.0", "Employer CPF (auto)" => "85.0", "Fuel and Energy (auto)" => "50.0", "Parking and ERP" => "30.0")
    expect(json[:data]).to include(revenue: "200.0", cost: "1765.0", profit: "-1565.0")
    expect(json.dig(:data, :break_even)).to include(runs: 2, per_run: "100.0", runs_needed: 18)

    get api_v1_finance_vehicles_pl_path, params: { month: "2026-10", basis: "cash" }
    expect(json[:data]).to include(revenue: "200.0", cost: "765.0")
    expect(json.dig(:data, :vehicles, 0)).to include(plate: "PC7475L", profit: "-565.0")
    expect(json.dig(:data, :chart).size).to eq(12)

    get api_v1_finance_vehicles_due_path
    expect(json[:data].map { |d| d[:kind] }).to eq(%w[road_tax insurance])
  end

  it "flags a cost far above the usual and marks it checked" do
    within_tenant(company) do
      (4..9).each { |m| FuelEntry.create!(vehicle: data[:bus], date: Date.new(2026, m, 10), kind: "diesel", quantity: 20, cost: 50) }
      FuelEntry.create!(vehicle: data[:bus], date: Date.new(2026, 10, 20), kind: "diesel", quantity: 80, cost: 250)
    end
    get api_v1_finance_vehicles_spikes_path, params: { month: "2026-10" }
    expect(json[:data]).to eq([ { vehicle_id: data[:bus].id, plate: "PC7475L", category: "Fuel and Energy (auto)", amount: "300.0", usual: "50.0",
                                  month: "2026-10-01", checked: false } ])
    post api_v1_finance_vehicles_spikes_ack_path, params: { vehicle_id: data[:bus].id, category: "Fuel and Energy (auto)", month: "2026-10" }, as: :json
    get api_v1_finance_vehicles_spikes_path, params: { month: "2026-10" }
    expect(json.dig(:data, 0, :checked)).to be(true)
  end
end
