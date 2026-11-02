require "rails_helper"

# HR > Bonuses: save rules, period options, a Trip Target bonus in the simulator, overlap with the scheme's incentive.
RSpec.describe "HR bonuses" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      van = create(:vehicle_type, name: "Van", seats: 13)
      plan = PayRatePlan.create!(name: "Flat")
      period = plan.periods.create!(name: "All Day", days: PayRatePeriod::DAYS)
      period.ranges.create!(start_time: "00:00", end_time: "23:59")
      period.rates.create!(vehicle_type: van, per_trip: 10, per_hour: 10)
      scheme = PayScheme.create!(name: "Basic", rate_plan: plan, is_default: true, has_monthly_target_incentive: true)
      scheme.target_tiers.create!(period: "monthly", target_trips: 2, amount: 30)
      { van:, scheme: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[finance]))
  end

  def save(id: nil, **attrs)
    body = { bonus: { name: "Nov Trip Bonus", plan_type: "trip_target", frequency: "monthly", starts_on: "2026-11-01",
                      tiers: [ { target_trips: 3, pay_as: "lump_sum", amount: 100, points: 50 } ] }.merge(attrs) }
    id ? patch(api_v1_pay_bonus_path(id), params: body, as: :json) : post(api_v1_pay_bonuses_path, params: body, as: :json)
  end

  def simulate(trips)
    post api_v1_pay_simulate_path, params: { scheme_id: data[:scheme].id, vehicle_type_id: data[:van].id, month: "2026-11",
                                             jobs: { "2026-11-03" => Array.new(trips) { |i| { type: "trip", start_time: "0#{i + 6}:00" } } } }, as: :json
  end

  it "checks the bonus and lists period options" do
    save(tiers: [])
    expect(json.dig(:error, :message)).to eq("Add at least one tier")
    save(payout_type: "split_trenches", payments: [ { percentage: 50, months_after: 1 }, { percentage: 30, months_after: 2 } ])
    expect(json.dig(:error, :message)).to eq("The split payments add up to 80%. They must add up to 100%")
    save(requires_sign_up: true)
    expect(json.dig(:error, :message)).to eq("Set the sign-up dates")
    save(plan_type: "reliability_otp", frequency: "weekly")
    expect(json.dig(:error, :message)).to eq("On-time and attendance bonuses run monthly or longer")
    save(last_period_on: "2026-12-01")
    expect(json[:data]).to include(status: "running", ends_on: "2026-12-31", type_label: "Trip Target", scheme_ids: [])

    get periods_api_v1_pay_bonuses_path, params: { frequency: "quarterly" }
    expect(json[:data].first).to eq(value: "2026-10-01", label: "Q4 2026, Oct to Dec")
  end

  it "pays the tier reached in the simulator and follows the overlap rule" do
    save
    simulate(3)
    expect(json.dig(:data, :bonuses, 0)).to include(name: "Nov Trip Bonus", sub: "Target reached", amount: "100.0", adjust: "0.0",
                                                    points: 50, paid_now: true, note: nil)
    expect(json[:data]).to include(total: "60.0", total_with_bonuses: "160.0") # 3 x 10 + monthly target 30, + bonus 100

    patch api_v1_pay_bonus_path(json.dig(:data, :bonuses, 0, :bonus_id)), params: { bonus: { overlap_monthly: "supercede" } }, as: :json
    simulate(3)
    expect(json.dig(:data, :bonuses, 0)).to include(amount: "100.0", adjust: "-30.0")
    expect(json[:data]).to include(total_with_bonuses: "130.0")

    simulate(2)
    expect(json.dig(:data, :bonuses, 0)).to include(sub: "Target not reached", amount: "0.0")
  end
end
