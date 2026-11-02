require "rails_helper"

# HR > Rate Plans: save the whole plan, rate lookup (overnight, PH, priority), coverage, lock / unlock, permissions.
RSpec.describe "HR rate plans" do
  let(:company) { create(:company) }
  let(:finance) { create(:user, company:, name: "Marcus Lim", permissions: %w[finance finview]) }
  let!(:types) { within_tenant(company) { { van: create(:vehicle_type, name: "Van", seats: 13), coach: create(:vehicle_type, name: "Coach", seats: 45) } } }

  def body(**over)
    { rate_plan: { name: "Standard", vehicle_type_ids: [ types[:van].id ],
                   periods: [
                     { name: "Day", days: %w[mon tue wed thu fri], ranges: [ { start_time: "07:00", end_time: "21:00" } ],
                       rates: [ { vehicle_type_id: types[:van].id, per_trip: 14, per_hour: 10 } ] },
                     { name: "Night", days: %w[mon tue wed thu fri], ranges: [ { start_time: "21:00", end_time: "07:00" } ],
                       rates: [ { vehicle_type_id: types[:van].id, per_trip: 17, per_hour: 13 } ] },
                     { name: "Weekend and PH", days: %w[sat sun ph], takes_priority: true, ranges: [ { start_time: "00:00", end_time: "23:59" } ],
                       rates: [ { vehicle_type_id: types[:van].id, per_trip: 18 } ] }
                   ] }.merge(over) }
  end

  before { sign_in_as(finance) }

  it "saves a plan, finds the rate of a moment and shows coverage" do
    post api_v1_pay_rate_plans_path, params: body(periods: []), as: :json
    expect(json.dig(:error, :message)).to eq("Add at least one period")

    post api_v1_pay_rate_plans_path, params: body, as: :json
    expect(response).to have_http_status(:created), json.inspect
    plan = json[:data]
    expect(plan[:periods].second).to include(name: "Night", ranges: [ { start_time: "21:00", end_time: "07:00", ends_next_day: true } ])

    lookup = within_tenant(company) do
      PublicHoliday.create!(date: Date.new(2026, 11, 9), name: "Deepavali")
      Pay::RateLookup.new(PayRatePlan.find(plan[:id]).tap { |p| p.periods.load }, holidays: Set[Date.new(2026, 11, 9)])
    end
    tue = Date.new(2026, 11, 3)
    expect(lookup.rate(tue, 8 * 60, types[:van].id)).to include(per_trip: 14)
    expect(lookup.rate(tue, (23 * 60) + 30, types[:van].id)).to include(per_trip: 17)
    expect(lookup.rate(tue, 1440 + 120, types[:van].id)).to include(per_trip: 17) # 02:00 Wed: Tue night
    expect(lookup.rate(Date.new(2026, 11, 9), 8 * 60, types[:van].id)).to include(per_trip: 18) # Monday PH
    expect(lookup.rate(Date.new(2026, 11, 8), 8 * 60, types[:coach].id)).to include(per_trip: 0) # type not in plan

    get coverage_api_v1_pay_rate_plan_path(plan[:id])
    rows = json.dig(:data, :rows)
    expect(rows[1][:cells][0]).to eq(plan[:periods][1][:id]) # Tue 00:15: Monday's night
    expect(rows[0][:cells][0]).to be_nil # Mon 00:15: Sunday has no night period
    expect(json.dig(:data, :gaps)).to eq([ { day: "mon", from: "00:00", to: "07:00" } ])
    expect(json.dig(:data, :empty_rates)).to eq([])
  end

  it "locks and unlocks, and only an Admin unlocks" do
    post api_v1_pay_rate_plans_path, params: body.merge(lock: true), as: :json
    id = json.dig(:data, :id)
    expect(json[:data]).to include(locked: true, locked_by: { id: finance.id, name: "Marcus Lim" })

    patch api_v1_pay_rate_plan_path(id), params: body(name: "Changed"), as: :json
    expect(json.dig(:error, :message)).to eq("Standard is locked. Ask an Admin to unlock it")
    post unlock_api_v1_pay_rate_plan_path(id)
    expect(response).to have_http_status(:forbidden)

    sign_in_as(create(:user, :admin, company:))
    post unlock_api_v1_pay_rate_plan_path(id)
    expect(json[:data]).to include(locked: false)
    delete api_v1_pay_rate_plan_path(id)
    expect(response).to have_http_status(:no_content)
  end

  it "is hidden without finance permissions" do
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
    get api_v1_pay_rate_plans_path
    expect(response).to have_http_status(:forbidden)
  end
end
