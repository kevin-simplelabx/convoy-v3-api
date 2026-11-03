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
    expect(json.dig(:data, :vehicles)).to eq([ { from: "2026-11-02", vehicle_id: bus.id, plate: "PD6604E" } ])
    post prices_api_v1_route_path(route), params: { effective_from: "2026-11-01", mode: "rider", base_price: 3000, riders_included: 15, per_rider: 60 }
    expect(json.dig(:data, :prices, 0)).to include(mode: "rider", base_price: "3000.0")
    post prices_api_v1_route_path(route), params: { effective_from: "2026-12-01", mode: "fixed" }
    expect(json.dig(:error, :message)).to eq("Monthly is needed")
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
end
