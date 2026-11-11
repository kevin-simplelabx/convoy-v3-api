require "rails_helper"

# School Bus › Route Plans › hand edits: a route's stops and riders (moved riders leave their old route, taken-off riders
# go to unassigned one by one, ADMIN_REMOVED), New Route (Manual badge), bus type, lock, delete, Reset Route (bus size
# kept), the summary rebuilt, and Route Again keeping locked routes and route ids (not on an adopted plan).
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
    expect(json.dig(:data, :unassigned)).to eq([ { gid: "rm:R11", riders: [ "R11" ], n: 1, reason: "ADMIN_REMOVED", label: "Rider 11" } ])
    expect(json.dig(:data, :summary)).to include(routes: 2, assigned: 11, unassigned: 1, riders: 12, fixed: 960.0, run: 40.0, total: 1000.0)

    post api_v1_plan_routes_path(plan_id), params: { bus_type: "SMALL_13", stops: [ { stop_point_id: points[0], riders: %w[R11] } ] }, as: :json
    expect(response).to have_http_status(:created)
    expect(routes["AM 3"]).to include(manual: true, locked: true, bus_type: "SMALL_13", riders_count: 1, badges: [ "Manual" ])
    expect(json.dig(:data, :unassigned)).to eq([])

    patch api_v1_route_path(am2), params: { route: { bus_type: "SMALL_13", locked: true } }
    expect(routes["AM 2"]).to include(bus_type: "SMALL_13", seats: 13, locked: true)

    post reset_api_v1_route_path(am1)
    expect(routes["AM 1"]).to include(edited: false, riders_count: 6)
    expect(routes["AM 2"][:stops].map { |x| x[:name] }).to eq([ "Stop 4" ])
    expect(json.dig(:data, :unassigned)).to eq(%w[R30 R31 R32].map { |rid| { gid: "rm:#{rid}", riders: [ rid ], n: 1, reason: "ADMIN_REMOVED", label: "Rider #{rid[1..]}" } })

    expect(routes.key?("AM 3")).to be(false) # its only rider went back to AM 1, so the route went
    post reset_api_v1_route_path(am2) # the engine's stops again; the bus size picked by hand stays
    expect(routes["AM 2"]).to include(edited: false, bus_type: "SMALL_13", seats: 13, riders_count: 6)
    expect(json.dig(:data, :unassigned)).to eq([])
    delete api_v1_route_path(am2)
    expect(json.dig(:data, :unassigned).map { it[:label] }).to eq([ "Rider 30", "Rider 31", "Rider 32", "Rider 40", "Rider 41", "Rider 42" ])
    expect(json.dig(:data, :summary)).to include(routes: 1, assigned: 6, unassigned: 6, riders: 12)
  end

  it "answers 503 routing_unavailable, without the service's own text, when Optimise cannot reach the routing service" do
    fake_routing.down = true
    get api_v1_plan_path(plan_id)
    am1 = json.dig(:data, :routes, 0, :id)
    [ optimise_api_v1_route_path(am1), api_v1_plan_optimise_path(plan_id) ].each do |path|
      post path
      expect(response).to have_http_status(:service_unavailable)
      expect(json[:error]).to eq(code: "routing_unavailable", message: "Routing service is not available")
    end
  end

  it "optimises the stop order of a route or of every route, and resets every edit" do
    get api_v1_plan_path(plan_id)
    am1 = json.dig(:data, :routes, 0, :id)
    post optimise_api_v1_route_path(am1)
    expect(json[:meta]).to eq(message: "AM 1 is already in the best order for its passengers")

    # Stop 2 before Stop 1: the best order (the stand-in engine: by point) puts them back
    put stops_api_v1_route_path(am1), params: { stops: [ { stop_point_id: points[1], riders: %w[R20 R21 R22] }, { stop_point_id: points[0], riders: %w[R10 R11 R12] } ],
                                                vias: [ [ [ 1.33, 103.93 ] ], [] ] }, as: :json
    post optimise_api_v1_route_path(am1)
    expect(json[:meta][:message]).to eq("AM 1 re-ordered. Journey 30 to 25 min, avg ride 50 to 40 min")
    expect(routes["AM 1"][:stops].map { |x| x[:name] }).to eq([ "Stop 1", "Stop 2" ])
    expect(routes["AM 1"][:vias]).to eq([ [], [] ]) # the leg Stop 2 → Stop 1 is gone, so its via points go
    post api_v1_plan_optimise_path(plan_id)
    expect(json[:meta][:message]).to eq("Every route is already in its best stop order")

    post api_v1_plan_routes_path(plan_id), params: { bus_type: "SMALL_13", stops: [ { stop_point_id: points[3], riders: %w[R40] } ] }, as: :json
    post api_v1_plan_reset_path(plan_id) # Reset All
    expect(json[:meta][:message]).to eq("All manual edits cleared, including routes drawn by hand")
    expect(routes.keys).to eq([ "AM 1", "AM 2" ])
    expect(routes.values.map { it[:edited] }).to all(be(false))
    expect(json.dig(:data, :summary)).to include(assigned: 12, unassigned: 0)
  end

  it "routes again around locked routes, keeping route ids, and not on an adopted plan" do
    get api_v1_plan_path(plan_id)
    am1, am2 = json.dig(:data, :routes).map { |r| r[:id] }
    patch api_v1_route_path(am1), params: { route: { locked: true } }
    perform_enqueued_jobs { post api_v1_plan_route_again_path(plan_id), params: { fleet: { MEDIUM_23: 3 } }, as: :json }
    expect(json[:data]).to include(kind: "again", plan_id:)
    expect(fake_routing.inputs.last["groups"].flat_map { |g| g["riders"] }).to eq(%w[R30 R31 R32 R40 R41 R42])

    get api_v1_plan_path(plan_id)
    expect(json.dig(:data, :routes).map { |r| [ r[:label], r[:locked], r[:stops].map { |s| s[:name] } ] })
      .to eq([ [ "AM 1", true, [ "Stop 1", "Stop 2" ] ], [ "AM 2", false, [ "Stop 3", "Stop 4" ] ] ])
    expect(json.dig(:data, :routes).map { |r| r[:id] }).to eq([ am1, am2 ]) # updated in place
    expect(json.dig(:data, :summary)).to include(routes: 2, assigned: 12, fixed: 960.0, total: 1000.0, slots: { "07:10": 2 })

    post adopt_api_v1_plan_path(plan_id), params: { from: "2026-11-02" }
    post api_v1_plan_route_again_path(plan_id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Make a new plan to route again")
  end
end
