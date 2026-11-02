require "rails_helper"

RSpec.describe RateCards::Quote, :tenant do
  let(:van) { create(:vehicle_type, key: "van", seats: 13) }
  let(:card) do
    RateCard.create!(name: "Standard Rates", default_card: true, distance_pricing: true, stop_fees: true).tap do |c|
      off = c.periods.create!(name: "Off Peak", days: %w[mon tue wed thu fri], position: 0)
      off.ranges.create!(starts_at: "07:00", ends_at: "19:00")
      off.rates.create!(vehicle_type: van, trip_rate: 55, hourly_rate: 45)
      night = c.periods.create!(name: "Night", days: %w[mon tue wed thu fri sun], position: 1)
      night.ranges.create!(starts_at: "21:00", ends_at: "05:00")
      night.rates.create!(vehicle_type: van, trip_rate: 75, hourly_rate: 65)
      wk = c.periods.create!(name: "Weekend and PH", days: %w[sat sun ph], override: true, position: 2)
      wk.ranges.create!(starts_at: "00:00", ends_at: "23:59")
      wk.rates.create!(vehicle_type: van, trip_rate: 70, hourly_rate: 60)
      near = c.distance_bands.create!(position: 0, up_to_km: 20)
      far = c.distance_bands.create!(position: 1, up_to_km: nil, per_km: true)
      c.amounts.create!(kind: "distance_band", rate_card_distance_band: near, vehicle_type: van, amount: 0)
      c.amounts.create!(kind: "distance_band", rate_card_distance_band: far, vehicle_type: van, amount: 2)
      c.amounts.create!(kind: "stop_fee", vehicle_type: van, amount: 10)
    end
  end

  def quote(date, time, **opts) = described_class.call(client: nil, date: Date.parse(date), start_time: time, vehicle_type: van, **opts)

  before { card }

  it "takes the period at the pick-up time, the distance band and the stop fees" do
    r = quote("2026-11-03", "09:00", km: 30, extra_stops: 2)
    expect(r.amount).to eq(55 + 20 + 20)
    expect(r.lines.map(&:text)).to eq([ "One Way, Off Peak", "Distance 30.0 km", "2 extra stops" ])
  end

  it "runs a night range past midnight and lets an override win on holidays" do
    expect(quote("2026-11-04", "02:00").lines.first.text).to eq("One Way, Night")
    create(:public_holiday, date: "2026-11-09")
    expect(quote("2026-11-09", "09:00").amount).to eq(70)
  end

  it "uses the client's own card and says when no period covers the time" do
    own = RateCard.create!(name: "Corporate")
    client = create(:client, rate_card: own)
    r = described_class.call(client:, date: Date.new(2026, 11, 3), start_time: "09:00", vehicle_type: van)
    expect([ r.card, r.missing ]).to eq([ own, "One Way: no period covers 09:00" ])
  end
end
