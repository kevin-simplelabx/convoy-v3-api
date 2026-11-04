require "rails_helper"

# School Bus › Route Plans: list and detail of plans made by routing runs, Draw Routes, rename, comments, Compare, delete
# a draft (not an adopted plan), Out of Date after the stops change.
RSpec.describe "School Bus route plans" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  def run_routing(session = "am")
    perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: } }
    get api_v1_routing_run_path(json.dig(:data, :id))
    json.dig(:data, :plan_id)
  end

  it "lists plans, shows one, renames, comments, compares and deletes drafts" do
    first = run_routing
    second = run_routing
    run_routing("pm")
    get api_v1_school_plans_path(school), params: { session: "am" }
    expect(json[:data].map { |p| [ p[:name], p[:state], p[:routes_count], p[:riders], p[:bus_mix] ] })
      .to eq([ [ "AM Plan 2", "draft", 2, 12, { MEDIUM_23: 2 } ], [ "AM Plan 1", "draft", 2, 12, { MEDIUM_23: 2 } ] ])

    get api_v1_plan_path(first)
    d = json[:data]
    expect(d[:summary]).to include(routes: 2, assigned: 12)
    expect(d[:routing_run]).to include(no_stop: [], conflicts: [])
    within_tenant(company) { SchoolRoute.find(d.dig(:routes, 0, :id)).update_column(:fill, 0.8696) }
    get api_v1_plan_path(first)
    expect(json.dig(:data, :routes, 0, :fill)).to eq(0.8696)
    stop = d.dig(:routes, 0, :stops, 0)
    expect(stop).to include(name: "Stop 1", time: "06:30", stop_code: "BDSZ03-0001", pudo_code: "BDSZ03-0001A", riders: %w[R10 R11 R12])

    patch api_v1_plan_path(first), params: { plan: { name: "AM Term 1 draft" } }
    post comments_api_v1_plan_path(first), params: { body: "Check Stop 4 timing" }
    expect(json[:data]).to include(name: "AM Term 1 draft", comments_count: 1)
    expect(json.dig(:data, :comments, 0)).to include(body: "Check Stop 4 timing", by: be_present)

    get compare_api_v1_plan_path(first), params: { with: second }
    expect(json[:data]).to include(routes: [ 2, 2 ], a: "AM Term 1 draft", b: "AM Plan 2")

    post api_v1_school_plans_path(school), params: { session: "am" }
    expect(json[:data]).to include(name: "AM Plan 3", source: "manual", routes_count: 0, state: "draft")

    within_tenant(company) { SchoolPlan.find(second).update!(in_use: true) }
    delete api_v1_plan_path(second)
    expect(json.dig(:error, :message)).to eq("Only a draft plan can be deleted")
    delete api_v1_plan_path(first)
    expect(response).to have_http_status(:no_content)

    travel 1.minute
    put api_v1_school_stop_path(school, within_tenant(company) { Stop.first.id }), params: { postal_codes: %w[460101 460102] }, as: :json
    get api_v1_plan_path(second)
    expect(json.dig(:data, :out_of_date)).to be(true)
  end
end
