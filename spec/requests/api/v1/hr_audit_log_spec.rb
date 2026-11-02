require "rails_helper"

# HR > Audit Log: lock / unlock, saves, assignments and points from `audits`, filtered by action, item and search.
RSpec.describe "HR audit log" do
  let(:company) { create(:company) }
  let(:admin) { create(:user, :admin, company:, name: "Olivia Owner") }
  let!(:data) do
    within_tenant(company) do
      plan = PayRatePlan.create!(name: "Standard")
      scheme = PayScheme.create!(name: "Basic + Trips", rate_plan: plan, is_default: true)
      { plan:, scheme:, eric: create(:driver, name: "Eric Pang") }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(admin)
  end

  it "lists HR changes of the company only, newest first" do
    post lock_api_v1_pay_rate_plan_path(data[:plan])
    post unlock_api_v1_pay_rate_plan_path(data[:plan])
    post assignments_api_v1_pay_driver_path(data[:eric], kind: "schemes"), params: { assignment: { pay_scheme_id: data[:scheme].id, starts_on: "2026-11-01" } }, as: :json
    post api_v1_pay_points_driver_path(data[:eric]), params: { kind: "award", points: 20, reason: "Good conduct" }, as: :json
    within_tenant(create(:company)) { PayRatePlan.create!(name: "Elsewhere") }

    get api_v1_pay_audit_log_path
    mine = json[:data].reject { |e| e[:action] == "create" && e[:item] != "driver_assignment" }
    expect(mine.map { |e| [ e[:action], e[:item], e[:name], e[:details] ] }).to eq([
      [ "award", "points", "Eric Pang", "Awarded 20 points: Good conduct" ],
      [ "create", "driver_assignment", "Eric Pang", "Assigned a scheme from 1 Nov 2026" ],
      [ "unlock", "rate_plan", "Standard", nil ],
      [ "lock", "rate_plan", "Standard", nil ]
    ])
    expect(mine.first).to include(user: "Olivia Owner", item_label: "Points")
    expect(json[:data].find { |e| e[:item] == "pay_scheme" }).to include(action: "create", details: "Created")
    expect(json[:data].pluck(:name)).not_to include("Elsewhere")

    get api_v1_pay_audit_log_path, params: { action_type: "lock" }
    expect(json[:data].size).to eq(1)
    get api_v1_pay_audit_log_path, params: { q: "conduct" }
    expect(json[:data].pluck(:action)).to eq([ "award" ])
  end
end
