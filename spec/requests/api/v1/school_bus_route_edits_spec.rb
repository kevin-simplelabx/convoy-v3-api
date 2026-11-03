require "rails_helper"

# School Bus › Route Plans › hand edits: a route's stops and riders (moved riders leave their old route, taken-off riders
# go to unassigned), New Route, bus type, lock, delete, Reset Route, and Route Again keeping locked routes.
RSpec.describe "School Bus route edits" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: "am" } }
  end

  let(:plan_id) { within_tenant(company) { SchoolPlan.last.id } }
  let(:points) { within_tenant(company) { Stop.order(:code).map { it.points.first.id } } }

  def routes = json.dig(:data, :routes).index_by { |r| r[:label] }

  it "edits a route's stops, moves riders between routes and adds a route" do
    get api_v1_plan_path(plan_id)
    am1, am2 = json.dig(:data, :routes).map { |r| r[:id] }

    # AM 1 takes Stop 3 from AM 2 and drops rider R11
    put stops_api_v1_route_path(am1), params: { stops: [ { stop_point_id: points[0], riders: %w[R10 R12] }, { stop_point_id: points[2], riders: %w[R30 R31 R32] },
                                                          { stop_point_id: points[1], riders: %w[R20 R21 R22] } ] }, as: :json
    r = routes
    expect(r["AM 1"]).to include(edited: true, riders_count: 8, badges: [ "Edited" ])
    expect(r["AM 1"][:stops].map { |s| [ s[:name], s[:time] ] }).to eq([ [ "Stop 1", "06:30" ], [ "Stop 3", "06:40" ], [ "Stop 2", "06:50" ] ])
    expect(r["AM 2"][:stops].map { |s| s[:name] }).to eq([ "Stop 4" ])
    expect(json.dig(:data, :unassigned)).to eq([ { riders: [ "R11" ], n: 1, reason: "Removed by hand", label: "Removed by hand" } ])
    expect(json.dig(:data, :summary)).to include(routes: 2, assigned: 11, unassigned: 1)

    post api_v1_plan_routes_path(plan_id), params: { bus_type: "SMALL_13", stops: [ { stop_point_id: points[0], riders: %w[R11] } ] }, as: :json
    expect(response).to have_http_status(:created)
    expect(routes["AM 3"]).to include(manual: true, locked: true, bus_type: "SMALL_13", riders_count: 1)
    expect(json.dig(:data, :unassigned)).to eq([])

    patch api_v1_route_path(am2), params: { route: { bus_type: "SMALL_13", locked: true } }
    expect(routes["AM 2"]).to include(bus_type: "SMALL_13", seats: 13, locked: true)

    post reset_api_v1_route_path(am1)
    expect(routes["AM 1"]).to include(edited: false, riders_count: 6)
    expect(routes["AM 2"][:stops].map { |x| x[:name] }).to eq([ "Stop 4" ])
    expect(json.dig(:data, :unassigned)).to eq([ { riders: %w[R30 R31 R32], n: 3, reason: "Taken off by Reset Route", label: "Taken off by Reset Route" } ])

    expect(routes.key?("AM 3")).to be(false) # its only rider went back to AM 1, so the route went
    delete api_v1_route_path(am2)
    expect(json.dig(:data, :unassigned).last).to include(riders: %w[R40 R41 R42], reason: "Route deleted")
  end

  it "routes again around locked routes" do
    get api_v1_plan_path(plan_id)
    am1 = json.dig(:data, :routes, 0, :id)
    patch api_v1_route_path(am1), params: { route: { locked: true } }
    perform_enqueued_jobs { post api_v1_plan_route_again_path(plan_id), params: { fleet: { MEDIUM_23: 3 } }, as: :json }
    expect(json[:data]).to include(kind: "again", plan_id:)
    expect(fake_routing.inputs.last["groups"].flat_map { |g| g["riders"] }).to eq(%w[R30 R31 R32 R40 R41 R42])

    get api_v1_plan_path(plan_id)
    expect(json.dig(:data, :routes).map { |r| [ r[:label], r[:locked], r[:stops].map { |s| s[:name] } ] })
      .to eq([ [ "AM 1", true, [ "Stop 1", "Stop 2" ] ], [ "AM 2", false, [ "Stop 3", "Stop 4" ] ] ])
  end
end
