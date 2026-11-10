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
    expect(json[:data].first).to include(category: "Parking and ERP", by: be_present)
    post api_v1_finance_vehicle_entries_path(data[:bus]), params: { entry: { kind: "cost", category: "School Bus", entry_on: "2026-09-05", amount: 30 } }, as: :json
    expect(json.dig(:error, :details, :category)).to eq([ "Category is not a cost category" ])

    get api_v1_finance_vehicle_pl_path(data[:bus]), params: { month: "2026-10", basis: "profit" }
    cats = json.dig(:data, :categories).to_h { |c| [ c[:category], c[:amount] ] }
    expect(cats).to eq("Ad Hoc / Charter (auto)" => "200.0", "Depreciation" => "1000.0", "Driver Salary (auto)" => "500.0",
                       "Insurance Premium (auto)" => "100.0", "Employer CPF (auto)" => "85.0", "Fuel and Energy (auto)" => "50.0", "Parking and ERP" => "30.0")
    expect(json[:data]).to include(revenue: "200.0", cost: "1765.0", profit: "-1565.0")
    expect(json.dig(:data, :break_even)).to include(runs: 2, per_run: "100.0", runs_needed: 18)
    dive = json.dig(:data, :categories).to_h { [ it[:category], it[:children] ] } # one level down, then another
    expect(dive["Ad Hoc / Charter (auto)"]).to eq([ { name: "No client set", amount: "200.0", children: [ { name: "Charter", amount: "200.0" } ] } ])
    expect(dive["Fuel and Energy (auto)"]).to eq([ { name: "Diesel", amount: "50.0", children: [ { name: "Company not set", amount: "50.0" } ] } ])
    expect(dive["Driver Salary (auto)"]).to eq([ { name: "Eric Pang", amount: "500.0", children: [] } ])
    expect(dive["Parking and ERP"]).to eq([ { name: "No note", amount: "30.0", children: [] } ])
    expect(dive["Depreciation"]).to eq([])

    get api_v1_finance_vehicles_pl_path, params: { month: "2026-10", basis: "cash" }
    expect(json[:data]).to include(revenue: "200.0", cost: "765.0")
    expect(json.dig(:data, :vehicles, 0)).to include(plate: "PC7475L", profit: "-565.0")
    expect(json.dig(:data, :vehicles, 0, :break_even)).to include(runs: 2, per_run: "100.0", runs_needed: 8) # cash: 765 of costs
    expect(json.dig(:data, :vehicles, 0, :categories).first).to eq(kind: "revenue", category: "Ad Hoc / Charter (auto)", amount: "200.0")
    expect(json.dig(:data, :chart).size).to eq(12)
    chart = json.dig(:data, :chart)
    expect(chart.each_cons(2).map { |a, b| (b[:running_total].to_d - a[:running_total].to_d) - b[:profit].to_d }.uniq).to eq([ 0 ]) # cumulative profit
    expect(chart.last[:running_total]).to eq(json.dig(:data, :running_total)) # the Month card
    expect(chart.last[:month]).to eq("2026-10")
    get api_v1_finance_vehicles_pl_path, params: { month: "2026-10", basis: "cash", period: "ytd" }
    expect(json[:data]).to include(running_total: nil)
    expect(json.dig(:data, :chart, 0)).to have_key(:running_total)
    get api_v1_finance_vehicle_pl_path(data[:bus]), params: { month: "2026-10", basis: "cash" }
    expect(json.dig(:data, :running_total)).to eq(json.dig(:data, :chart, -1, :running_total))

    get api_v1_finance_vehicles_due_path
    expect(json[:data].map { |d| d[:kind] }).to eq(%w[road_tax insurance])
  end

  it "earns the route pay of School Bus routes the bus runs, by school and route" do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      school.bus_size_rates.create!(bus_type: "MEDIUM_23", monthly: 4200)
      plan = school.plans.create!(name: "AM Plan", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
      route = plan.routes.create!(number: 1, label: "AM 1", start_time: "07:00", end_time: "07:30", bus_type: "MEDIUM_23")
      route.vehicle_changes.create!(vehicle: data[:bus], effective_from: Date.new(2026, 10, 1))
    end
    get api_v1_finance_vehicle_pl_path(data[:bus]), params: { month: "2026-10", basis: "profit" }
    school_bus = json.dig(:data, :categories).find { it[:category] == "School Bus (auto)" }
    expect(school_bus).to include(kind: "revenue", amount: "4200.0")
    expect(school_bus[:children]).to eq([ { name: "St. Stephen's School", amount: "4200.0", children: [ { name: "AM 1", amount: "4200.0" } ] } ])
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
