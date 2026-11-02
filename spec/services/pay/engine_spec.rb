require "rails_helper"

# Pay::Engine / Pay::Month on small months worked out by hand (rates: S$14 a trip, S$10 an hour, every day and time).
RSpec.describe Pay::Month, :tenant do
  let(:van) { create(:vehicle_type, name: "Van", seats: 13) }
  let(:plan) do
    PayRatePlan.create!(name: "Flat").tap do |p|
      period = p.periods.create!(name: "All Day", days: PayRatePeriod::DAYS)
      period.ranges.create!(start_time: "00:00", end_time: "23:59")
      period.rates.create!(vehicle_type: van, per_trip: 14, per_hour: 10)
    end
  end
  let(:basic) { PayScheme.create!(name: "Basic", rate_plan: plan, basic_salary: 500, basic_covers_daily_trips: true, basic_covered_daily_trips: 1) }
  let(:nov) { Date.new(2026, 11, 1) }

  def trip(day, at, tv: 1, ref: nil) = Pay::Engine::Job.new(date: Date.new(2026, 11, day), kind: :trip, start: Clock.minutes(at), tv:, vehicle_type_id: van.id, ref:)
  def hours(day, from, to) = Pay::Engine::Job.new(date: Date.new(2026, 11, day), kind: :hours, start: Clock.minutes(from), finish: Clock.minutes(to), vehicle_type_id: van.id)
  def month(jobs, scheme: basic, **opts) = described_class.call(month: nov, schemes: ->(_d) { scheme }, jobs:, holidays: Set.new, **opts)

  it "covers the first trip of a weekday with the basic and pays the rest at the rate" do
    r = month([ trip(3, "07:00", ref: "a"), trip(3, "08:00", ref: "b"), trip(3, "09:00", tv: 1.5, ref: "c"), hours(4, "17:00", "19:30") ])
    expect(r.total).to eq(500 + (14 * 2.5) + 25)
    expect(r.job_pay).to eq("a" => 0, "b" => 14, "c" => 21)
    expect(r.parts.first.rows.map { |x| x[:label] }).to include("Basic Salary", "Included in Base Pay", "Trip Pay", "Disposal Hours", "Disposal Pay")
  end

  it "tops up to the guarantee and pays on-top days in full" do
    basic.update!(has_guarantee: true, guaranteed_amount: 2200, on_top_sat: true)
    r = month([ trip(3, "07:00"), trip(3, "08:00"), trip(7, "10:00") ]) # Tue covered + 14; Sat 14 on top
    part = r.parts.first
    expect(part.parts).to include(top_up: 2200 - 514, trip_pay: 28)
    expect(r.total).to eq(2200 + 14)
  end

  it "adds the daily volume boost from the tier's trip number" do
    basic.update!(has_daily_volume_incentive: true)
    basic.volume_tiers.create!(from_trip: 2, boost_type: "flat", boost_value: 2)
    r = month([ trip(3, "07:00"), trip(3, "08:00"), trip(3, "09:00") ])
    expect(r.parts.first.parts).to include(trip_pay: 28, daily_volume: 4)
  end

  it "splits the month between schemes and pays fixed pay by the days of each part" do
    monthly = PayScheme.create!(name: "Monthly", rate_plan: plan, scheme_type: "monthly_with_minimum", monthly_pay_amount: 2400, monthly_daily_trips: 0)
    r = described_class.call(month: nov, schemes: ->(d) { d.day <= 15 ? basic : monthly }, jobs: [], holidays: Set.new)
    expect(r.parts.map { |p| [ p.scheme.name, p.from.day, p.to.day, p.total ] }).to eq([ [ "Basic", 1, 15, 250 ], [ "Monthly", 16, 30, 1200 ] ])
    expect(r.total).to eq(1450)
  end

  it "pays nothing on days without a scheme" do
    r = described_class.call(month: nov, schemes: ->(_d) { }, jobs: [ trip(3, "07:00", ref: "a") ], holidays: Set.new)
    expect(r.total).to eq(0)
    expect(r.job_pay).to eq("a" => 0)
  end
end
