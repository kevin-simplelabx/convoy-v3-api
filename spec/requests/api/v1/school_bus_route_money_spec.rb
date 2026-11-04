require "rails_helper"

# School Bus › Route Plans › route bus and money: the regular bus from a date, the operator's price history, Route
# Charges on runs when the school pays per bus, carried to a newly adopted plan for checking.
RSpec.describe "School Bus route money" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans finance]))
    2.times { perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: "am" } } }
  end

  let(:plans) { within_tenant(company) { SchoolPlan.order(:id).to_a } }

  it "sets the regular bus and the operator price from a date" do
    route = within_tenant(company) { plans.first.routes.first }
    bus = within_tenant(company) { create(:vehicle, plate: "PD6604E") }
    post vehicle_api_v1_route_path(route), params: { vehicle_id: bus.id, from: "2026-11-02" }
    expect(json.dig(:data, :vehicles)).to match([ { id: Integer, from: "2026-11-02", vehicle_id: bus.id, plate: "PD6604E", by: be_present } ])
    first_change = json.dig(:data, :vehicles, 0, :id)
    post vehicle_api_v1_route_path(route), params: { vehicle_id: "", from: "2026-11-20" }
    later = json.dig(:data, :vehicles, 1, :id)
    delete api_v1_route_vehicle_change_path(route, first_change)
    expect(json.dig(:error, :message)).to eq("The first bus of the route cannot be removed. Change it instead")
    delete api_v1_route_vehicle_change_path(route, later) # Remove this change
    expect(json.dig(:data, :vehicles).map { it[:plate] }).to eq([ "PD6604E" ])

    post prices_api_v1_route_path(route), params: { effective_from: "2026-11-01", mode: "rider", base_price: 3000, riders_included: 15, per_rider: 60 }
    expect(json.dig(:data, :prices, 0)).to include(mode: "rider", base_price: "3000.0")
    post prices_api_v1_route_path(route), params: { effective_from: "2026-12-01", mode: "fixed" }
    expect(json.dig(:error, :message)).to eq("Monthly is needed")
    price = within_tenant(company) { route.prices.sole.id }
    delete api_v1_route_price_path(route, price)
    expect(json.dig(:data, :prices)).to eq([])
  end

  it "adds Route Charges and carries them to the next adopted plan for checking" do
    first, second = plans
    post adopt_api_v1_plan_path(first), params: { from: "2026-11-02" }
    route = within_tenant(company) { first.routes.first }
    post charges_api_v1_route_path(route), params: { starts_on: "2026-11-02", kind: "amt", value: 150, reason: "Long route" }
    post charges_api_v1_route_path(route), params: { starts_on: "2026-12-01", kind: "pct", value: 10, reason: "Peak timing" }
    get api_v1_school_route_charges_path(school)
    run = json.dig(:data, :runs).find { |r| r[:route_id] == route.id }
    expect(run).to include(label: "AM 1", extra: "150.0")
    expect(run[:next]).to include(starts_on: "2026-12-01", kind: "pct")

    delete "/api/v1/route_charges/#{run.dig(:now, :id)}"
    expect(json.dig(:error, :message)).to start_with("Only a change that has not started can be removed")

    post adopt_api_v1_plan_path(second), params: { from: "2026-11-16" }
    get api_v1_school_route_charges_path(school), params: { date: "2026-11-16" }
    expect(json.dig(:data, :to_check)).to eq(1)
    carried = json.dig(:data, :runs).find { |r| r[:plan_id] == second.id && r[:now] }
    expect(carried[:now]).to include(status: "check", value: "150.0", reason: "Long route")
    patch api_v1_route_charge_path(carried.dig(:now, :id)), params: { status: "ok" }
    expect(json[:data]).to include(status: "ok")
  end

  it "records replacement buses in the route drawer, also a bus not in our list" do
    first = plans.first
    post adopt_api_v1_plan_path(first), params: { from: "2026-11-02" }
    route, bus, alpha = within_tenant(company) do
      r = first.routes.first
      b = create(:vehicle, plate: "PD6604E")
      r.vehicle_changes.create!(vehicle: b, effective_from: Date.new(2026, 11, 2))
      [ r, b, create(:operator, name: "Alpha Bus") ]
    end
    post replacements_api_v1_route_path(route), params: { from: "2026-11-10", to: "2026-11-11", plate: "sbs 1234a" }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the company that owns the bus")
    post replacements_api_v1_route_path(route), params: { from: "2026-11-10", plate: "SBS1234A", company: "Lim Transport", arranged_by: "us" }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the cost per day")
    post replacements_api_v1_route_path(route), params: { from: "2026-11-10", to: "2026-11-11", plate: "sbs 1234a", company: "Lim Transport",
                                                          arranged_by: "us", daily_rate: 180, reason: "Aircon" }, as: :json
    expect(response).to have_http_status(:created)
    expect(json[:data].sole).to include(starts_on: "2026-11-10", ends_on: "2026-11-11", vehicle: hash_including(plate: "SBS1234A"), company: "Lim Transport",
                                        arranged_by: "us", daily_rate: "180.0", deduct_from_operator: true, school_days: 2)
    post replacements_api_v1_route_path(route), params: { from: "2026-11-16", plate: "PA1001A", operator_id: alpha.id }, as: :json # a Transport Operator's bus
    expect(json[:data].first).to include(company: "Alpha Bus", arranged_by: "operator", daily_rate: nil)

    runs = -> { within_tenant(company) { TripOccurrence.where(school_route: route, date: Date.new(2026, 11, 10)).pluck(:vehicle_id) } }
    expect(runs.()).not_to include(bus.id)
    delete api_v1_route_replacement_path(json.dig(:data, 1, :id))
    expect(response).to have_http_status(:no_content)
    expect(runs.()).to all(eq(bus.id))
  end
end
