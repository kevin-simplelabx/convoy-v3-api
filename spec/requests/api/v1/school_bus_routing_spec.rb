require "rails_helper"

# School Bus › Route Plans › Run Routing: the engine input from Stop Assignment (riders with one stop, grouped), the
# background run in the routing service, its draft plan, riders with no stop ({ rid, name }), and the run's failures; the
# company's parameters.
RSpec.describe "School Bus routing runs" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "runs routing for a session and makes a draft plan from the result" do
    within_tenant(company) { school.riders.create!(rid: "X1", name: "Far away", postal: "469999", lat: 1.4, lng: 103.99, source: "manual") }
    perform_enqueued_jobs do
      post api_v1_school_routing_runs_path(school), params: { session: "am", date: "2026-11-02", params: { preset: "BALANCED" } }, as: :json
    end
    expect(response).to have_http_status(:accepted)
    run = json[:data]
    expect(run).to include(status: "queued", riders: 12, stops: 4, no_stop: [ { rid: "X1", name: "Far away" } ], conflicts: [])

    input = fake_routing.inputs.last
    expect(input["school"]).to include("lat" => 1.3138, "short" => "SSS")
    expect(input["groups"].first).to include("stopId" => "BDSZ03-0001", "riders" => %w[R10 R11 R12])
    expect(input["params"]).to include("session" => "AM", "preset" => "BALANCED", "attendant" => "STATUTORY")
    expect(input["noStop"]).to eq([ { "rid" => "X1", "name" => "Far away" } ]) # the engine labels its unassigned riders with these

    get api_v1_routing_run_path(run[:id])
    expect(json[:data]).to include(status: "done", ms: 1200, progress: { step: "done", frac: 1, work: { evals: nil } })
    within_tenant(company) { RoutingRun.find(run[:id]).update_columns(status: "running") } # rubocop:disable Rails/SkipsModelValidations
    get api_v1_routing_run_path(run[:id]) # while running: the routing service's progress
    expect(json.dig(:data, :progress)).to include(step: "solving", frac: 0.5, work: hash_including(phase: "Swap and relocate pass", evals: 1200))
    within_tenant(company) { RoutingRun.find(run[:id]).update_columns(status: "done") } # rubocop:disable Rails/SkipsModelValidations
    within_tenant(company) do
      plan = SchoolPlan.find(json.dig(:data, :plan_id))
      expect(plan).to have_attributes(name: "AM Plan 1", session: "am", source: "engine", in_use: false, priority: "BALANCED")
      expect(plan.routes.map(&:label)).to eq([ "AM 1", "AM 2" ])
      route = plan.routes.first
      expect(route).to have_attributes(bus_type: "MEDIUM_23", riders_count: 6, start_time_hm: "06:30", end_time_hm: "07:10")
      expect(route.stops.map(&:name)).to eq([ "Stop 1", "Stop 2" ])
      expect(route.stops.first.riders.map(&:rid)).to eq(%w[R10 R11 R12])
      expect(route.stops.first.stop_point).to be_present
      expect(plan.unassigned).to eq([ { "gid" => nil, "riders" => [ "X1" ], "n" => 1, "reason" => "RIDER_NO_STOP", "label" => "Far away" } ])
    end
    get api_v1_plan_path(json.dig(:data, :plan_id))
    expect(json.dig(:data, :routing_run)).to include(no_stop: [ { rid: "X1", name: "Far away" } ], conflicts: [])
  end

  it "fails the run when the engine or the service cannot plan, and still runs with no rider at a stop" do
    fake_routing.fail = true
    perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: "pm" } }
    get api_v1_routing_run_path(json.dig(:data, :id))
    expect(json[:data]).to include(status: "failed", error: "Road travel times could not be loaded", plan_id: nil)

    fake_routing.fail = false
    fake_routing.down = true
    perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: "pm" } }
    get api_v1_routing_run_path(json.dig(:data, :id))
    expect(json.dig(:data, :error)).to start_with("The routing service is not available")

    fake_routing.down = false
    expect { perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: "asa" } } } # Convoy OS runs it too
      .not_to(change { fake_routing.inputs.size })
    expect(response).to have_http_status(:accepted)
    get api_v1_routing_run_path(json.dig(:data, :id))
    expect(json[:data]).to include(status: "done", stops: 0, plan_id: Integer)
  end

  it "is done with an empty plan and every rider unassigned when no rider has a stop, without calling the engine" do
    lone = within_tenant(company) do
      School.create!(name: "Lone School", short_name: "LS", postal: "455788", lat: 1.3138, lng: 103.9283).tap do |s|
        s.riders.create!(rid: "X1", name: "Far away", postal: "469999", lat: 1.4, lng: 103.99, source: "manual")
        s.riders.create!(rid: "X2", name: "Further", postal: "469998", lat: 1.41, lng: 103.99, source: "manual")
      end
    end
    expect { perform_enqueued_jobs { post api_v1_school_routing_runs_path(lone), params: { session: "am", params: { preset: "BALANCED" } }, as: :json } }
      .not_to(change { fake_routing.inputs.size }) # no stop point = no road times: the routing service is not asked
    get api_v1_routing_run_path(json.dig(:data, :id))
    expect(json[:data]).to include(status: "done", error: nil, riders: 0, stops: 0, ms: 0, plan_id: Integer,
                                   no_stop: [ { rid: "X1", name: "Far away" }, { rid: "X2", name: "Further" } ])

    within_tenant(company) do
      run = RoutingRun.find(json.dig(:data, :id))
      expect(run.result).to include("status" => "COMPLETED_WITH_UNASSIGNED", "road" => false, "routes" => [], "assign" => {}, "dir" => "pickup",
                                    "validation" => [ { "code" => "RIDER_NO_STOP", "level" => "Warning", "msg" => "2 riders have no stop. Excluded from this run" } ])
      expect(run.result["params"]).to include("session" => "AM", "preset" => "BALANCED", "effort" => "high", "hardCap" => 75) # engine defaults + the run's
      plan = run.plan
      expect(plan).to have_attributes(source: "engine", in_use: false, priority: "BALANCED", effective_from: Date.current)
      expect(plan.routes).to be_empty
      expect(plan.unassigned).to eq([ { "gid" => nil, "riders" => [ "X1" ], "n" => 1, "reason" => "RIDER_NO_STOP", "label" => "Far away" },
                                     { "gid" => nil, "riders" => [ "X2" ], "n" => 1, "reason" => "RIDER_NO_STOP", "label" => "Further" } ])
      expect(plan.summary).to include("riders" => 2, "assigned" => 0, "unassigned" => 2, "routes" => 0, "total" => 0)
    end
  end

  it "keeps the company's engine parameters" do
    put "/api/v1/routing/settings", params: { params: { hardCap: 70, effort: "medium" } }, as: :json
    get "/api/v1/routing/settings"
    expect(json[:data]).to include(params: { hardCap: 70, effort: "medium" }, max_effort: "high")
    expect(json.dig(:data, :defaults)).to include(hardCap: 75)
  end
end
