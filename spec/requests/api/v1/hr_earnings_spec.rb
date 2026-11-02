require "rails_helper"

# HR > Earnings: pay from the Scheduler's runs (completed, no issue), Confirm / Reopen Month, issues frozen once confirmed.
RSpec.describe "HR earnings" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      van = create(:vehicle_type, name: "Van", seats: 13)
      plan = PayRatePlan.create!(name: "Flat")
      period = plan.periods.create!(name: "All Day", days: PayRatePeriod::DAYS)
      period.ranges.create!(start_time: "00:00", end_time: "23:59")
      period.rates.create!(vehicle_type: van, per_trip: 14, per_hour: 10)
      PayScheme.create!(name: "Basic", rate_plan: plan, basic_salary: 500, is_default: true)
      eric = create(:driver, name: "Eric Pang")
      bus = create(:vehicle, plate: "PD1234A", seats: 13)
      trip = create(:trip, title: "Office Shuttle")
      occ = ->(day, from, to, **attrs) do
        date = Date.new(2026, 10, day)
        TripOccurrence.create!({ trip:, date:, start_time: from, end_time: to, starts_at: date.in_time_zone.change(hour: from / 60),
                                 ends_at: date.in_time_zone.change(hour: to / 60), kind: "ad_hoc", trip_label: "T-#{day}-#{from}",
                                 vehicle: bus, driver: eric, trip_value: 1, run_key: "r#{day}#{from}", slot_no: from }.merge(attrs))
      end
      { eric:, runs: [ occ.(6, 480, 540), occ.(6, 600, 660, trip_value: 1.5), occ.(7, 480, 540, kind: "disposal", end_time: 630, ends_at: Date.new(2026, 10, 7).in_time_zone.change(hour: 10, min: 30)),
                       occ.(8, 480, 540, status: "cancelled", cancelled_at: Time.current) ] }
    end
  end
  let(:eric) { data[:eric] }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, :admin, company:, name: "Marcus Lim"))
  end

  it "pays completed runs, holds runs with an issue, then confirms and reopens the month" do
    get api_v1_pay_earnings_path, params: { month: "2026-10" }
    row = json[:data].find { |r| r[:driver_id] == eric.id }
    expect(row).to include(total: "560.0", completed: 3, held: 0, status: "to_confirm") # 500 + 14 + 1.5 x 14 + 2.5 h x 10

    post issue_api_v1_occurrence_path(data[:runs].first), params: { reason: "Client complaint" }, as: :json
    get api_v1_pay_earning_path(eric), params: { month: "2026-10" }
    expect(json[:data]).to include(status: "held", held: 1, can_confirm: false, why: "1 trip has an issue raised. Clear them first")
    expect(json.dig(:data, :runs).map { |r| [ r[:status], r[:amount] ] }).to eq([ [ "issue", nil ], [ "completed", "21.0" ], [ "completed", "25.0" ], [ "cancelled", nil ] ])

    delete issue_api_v1_occurrence_path(data[:runs].first)
    post api_v1_pay_earning_confirm_path(eric), params: { month: "2026-10" }
    expect(json[:data]).to include(status: "confirmed", total: "560.0", confirmed: hash_including(by: "Marcus Lim"))
    expect(json.dig(:data, :breakdown, 0, :rows).first).to include(label: "Basic Salary", amount: "500.0")

    post issue_api_v1_occurrence_path(data[:runs].first), params: { reason: "Late" }, as: :json
    expect(json.dig(:error, :message)).to eq("Driver pay for October 2026 is confirmed. Reopen it in HR, Earnings first")

    delete api_v1_pay_earning_confirm_path(eric), params: { month: "2026-10" }
    expect(json[:data]).to include(status: "to_confirm", confirmed: nil)
  end

  it "waits for the month to end" do
    get api_v1_pay_earning_path(eric), params: { month: "2026-11" }
    expect(json[:data]).to include(status: "open", why: "The month can be confirmed from 1 Dec 2026")
  end
end
