require "rails_helper"

RSpec.describe Pricing::TripPrice, :tenant do
  let(:company) { ActsAsTenant.current_tenant }

  def ctx(month = Date.new(2026, 11, 1)) = Calendars::Context.for(company, from: month, to: month.end_of_month)

  it "shares a whole-route price over the vehicles and adds the meet and greet fee to vehicle 1" do
    t = create(:trip, kind: :airport_transfer, airport_direction: :arrival, wait_minutes: 20, meet_and_greet: true,
                      meet_and_greet_fee: 25, price: 200, vehicles_count: 2, price_per: :route)
    p = described_class.new(t, ctx)
    expect([ p.run_price(slot: 1, date: t.starts_on), p.run_price(slot: 2, date: t.starts_on) ]).to eq([ 125, 100 ])
  end

  it "uses each vehicle's own price and the hourly rate for a disposal" do
    t = create(:trip, kind: :disposal, hours: 4, end_time: nil, hourly_rate: true, price: 50, vehicles_count: 2,
                      price_per: :vehicle, price_set: :each)
    t.vehicle_slots.create!(slot_no: 2, price: 60)
    p = described_class.new(t.reload, ctx)
    expect([ p.run_price(slot: 1, date: t.starts_on), p.run_price(slot: 2, date: t.starts_on) ]).to eq([ 200, 240 ])
  end

  it "spreads a monthly price over the days the trip runs that month" do
    create(:public_holiday, date: "2026-11-09")
    t = create(:trip, :weekdays, price: 2000, price_basis: :month)
    # November 2026 from the 2nd: 21 weekdays, less the holiday = 20
    expect(described_class.new(t, ctx).run_price(slot: 1, date: Date.new(2026, 11, 10))).to eq(100)
  end
end
