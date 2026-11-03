require "rails_helper"

# School Bus › Route Plans › Adopt: a plan runs on the Scheduler from its date (Current / Scheduled), the plan before
# ends the day before, Cancel puts it back; adopting an AM plan assigns riders' PUDO points (Stop Assignment), Set as
# assigned / Move All Riders Here by hand, Notify.
RSpec.describe "School Bus plan adoption" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { school_with_stops(company) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
    2.times { perform_enqueued_jobs { post api_v1_school_routing_runs_path(school), params: { session: "am" } } }
  end

  let(:plans) { within_tenant(company) { SchoolPlan.order(:id).pluck(:id) } }

  it "adopts plans, schedules one, cancels it, and runs them on the Scheduler" do
    first, second = plans
    post adopt_api_v1_plan_path(first), params: { from: "2026-10-31" }
    expect(json.dig(:error, :message)).to eq("Pick a date from the 1st of this month")

    post adopt_api_v1_plan_path(first), params: { from: "2026-11-02" }
    expect(json[:data]).to include(state: "current", effective_from: "2026-11-02", effective_to: nil)
    perform_enqueued_jobs
    runs = within_tenant(company) { TripOccurrence.where(school_route_id: SchoolRoute.where(school_plan_id: first).select(:id), date: Date.new(2026, 11, 3)).count }
    expect(runs).to eq(2)

    post adopt_api_v1_plan_path(second), params: { from: "2026-11-01" }
    expect(json.dig(:error, :message)).to eq("Pick a date after 2 Nov 2026, when the current plan started")
    post adopt_api_v1_plan_path(second), params: { from: "2026-11-16" }
    expect(json[:data]).to include(state: "scheduled", effective_from: "2026-11-16")
    get api_v1_plan_path(first)
    expect(json[:data]).to include(state: "current", effective_to: "2026-11-15")

    post cancel_adoption_api_v1_plan_path(second)
    expect(json[:data]).to include(state: "draft")
    get api_v1_plan_path(first)
    expect(json.dig(:data, :effective_to)).to be_nil
  end

  it "assigns riders' PUDO points from the adopted AM plan, by hand, and records Notify" do
    post adopt_api_v1_plan_path(plans.first), params: { from: "2026-11-02" }
    get api_v1_school_stop_assignment_path(school)
    expect(json.dig(:meta, :counts)).to include(assigned: 12, notified: 0)
    r10 = json[:data].find { |r| r[:rid] == "R10" }
    expect(r10[:assigned]).to include(pudo_code: "BDSZ03-0001A", manual: false)

    stop2 = within_tenant(company) { Stop.find_by(code: "BDSZ03-0002") }
    second_point = within_tenant(company) { stop2.all_points.create!(suffix: "B", usage: "both", sizes: %w[S], lat: 1.329, lng: 103.927).id }
    post api_v1_school_rider_assignments_path(school), params: { rids: %w[R10], stop_point_id: second_point }
    expect(json[:data]).to eq(assigned: 1)
    post move_api_v1_school_rider_assignments_path(school), params: { stop_point_id: second_point }
    expect(json[:data]).to eq(moved: 3) # R20, R21, R22 from point A of the same stop
    post notify_api_v1_school_rider_assignments_path(school)
    expect(json[:data]).to eq(notified: 12)

    get api_v1_school_stop_assignment_path(school)
    expect(json[:data].find { |r| r[:rid] == "R10" }[:assigned]).to include(pudo_code: "BDSZ03-0002B", manual: true, notified_at: be_present)
  end
end
