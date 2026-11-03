require "rails_helper"

# HR › Earnings: On-Time Performance and Attendance bonuses from what the Convoy Driver app recorded — on time over the
# completed runs with arrivals (within the company's allowance), attendance over the runs given (started in the app;
# a skipped trip is missed, a trip the client cancelled does not count), the bonus's Excluded Days left out.
RSpec.describe "HR reliability bonuses" do
  let(:company) { create(:company, on_time_minutes: 5) }
  let!(:data) do
    within_tenant(company) do
      van = create(:vehicle_type, name: "Van", seats: 13)
      plan = PayRatePlan.create!(name: "Flat")
      period = plan.periods.create!(name: "All Day", days: PayRatePeriod::DAYS)
      period.ranges.create!(start_time: "00:00", end_time: "23:59")
      period.rates.create!(vehicle_type: van, per_trip: 10, per_hour: 10)
      PayScheme.create!(name: "Basic", rate_plan: plan, basic_salary: 500, is_default: true)
      eric = create(:driver, name: "Eric Pang")
      bus = create(:vehicle, plate: "PD1234A", seats: 13)
      trip = create(:trip, title: "Office Shuttle")
      # Oct 5–14: one run a day. Late on the 6th (12 min); no arrival on the 7th; not started on the 8th (missed); the
      # driver skipped the 9th; the client cancelled the 12th; the 13th–14th fall in the Excluded Days (missed, ignored).
      (5..14).each do |day|
        date = Date.new(2026, 10, day)
        at = date.in_time_zone.change(hour: 8)
        attrs = { trip:, date:, start_time: 480, end_time: 540, starts_at: at, ends_at: at + 1.hour, kind: "ad_hoc", trip_label: "T-#{day}",
                  vehicle: bus, driver: eric, trip_value: 1, run_key: "r#{day}", status: "completed", started_at: at - 5.minutes,
                  max_delay_minutes: day == 6 ? 12 : 1 }
        attrs.merge!(max_delay_minutes: nil) if day == 7
        attrs.merge!(started_at: nil, max_delay_minutes: nil) if [ 8, 13, 14 ].include?(day)
        attrs.merge!(status: "cancelled", started_at: nil, driver_end: "skipped", max_delay_minutes: nil) if day == 9
        attrs.merge!(status: "cancelled", started_at: nil, cancelled_by_client: true, max_delay_minutes: nil) if day == 12
        TripOccurrence.create!(attrs)
      end
      { eric: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  def bonus(plan_type, excluded = [])
    post api_v1_pay_bonuses_path, params: { bonus: {
      name: plan_type == "reliability_otp" ? "On-Time October" : "Full Attendance", plan_type:, frequency: "monthly", starts_on: "2026-10-01",
      tiers: [ { metric_min: 70, metric_max: 89.9, pay_as: "lump_sum", amount: 20, points: 5 }, { metric_min: 90, pay_as: "lump_sum", amount: 50, points: 10 } ],
      excluded_periods: excluded
    } }, as: :json
    expect(response).to have_http_status(:created), json.inspect
  end

  def lines
    get api_v1_pay_earning_path(data[:eric]), params: { month: "2026-10" }
    json.dig(:data, :bonuses).to_h { [ it[:name], it.slice(:sub, :amount, :points) ] }
  end

  it "pays the tiers from the recorded on-time and attendance rates, leaving out Excluded Days" do
    bonus("reliability_otp")
    bonus("reliability_attendance", [ { name: "Depot shutdown", starts_on: "2026-10-13", ends_on: "2026-10-14" } ])

    # on time: arrivals known on the 5th, 6th, 10th, 11th; 3 within 5 min = 75%
    # attendance: given the 5th–11th (the 12th client-cancelled, the 13th–14th excluded) = 7; started 5 = 71.4%
    expect(lines).to eq(
      "On-Time October" => { sub: "75.0% on time", amount: "20.0", points: 5 },
      "Full Attendance" => { sub: "71.4% attendance", amount: "20.0", points: 5 }
    )

    within_tenant(company) { TripOccurrence.where(date: Date.new(2026, 10, 6)).update_all(max_delay_minutes: 4) }
    expect(lines["On-Time October"]).to eq(sub: "100.0% on time", amount: "50.0", points: 10)
  end

  it "says when nothing was recorded yet" do
    bonus("reliability_otp")
    within_tenant(company) { TripOccurrence.update_all(max_delay_minutes: nil) }
    expect(lines["On-Time October"]).to eq(sub: "No arrivals recorded yet for on time", amount: "0.0", points: 0)
  end
end
