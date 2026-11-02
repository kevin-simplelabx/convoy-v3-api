require "rails_helper"

# Fleet > Maintenance page: tabs with counts, search, KPI tiles, spend of the last 12 months, tyre changes.
RSpec.describe "Maintenance page" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      shop = Workshop.create!(name: "Ah Huat Motor Works")
      tyre_pro = Workshop.create!(name: "Tyre Pro Ubi")
      van = create(:vehicle, plate: "PD1A")
      coach = create(:vehicle, plate: "PD2B", seats: 45)
      visit = ->(vehicle, date, **attrs) { MaintenanceVisit.create!({ vehicle:, date:, start_time: "09:00", end_time: "11:00", workshop: shop }.merge(attrs)) }
      line = ->(type, qty, unit, **attrs) { { line_type: type, description: "Item", quantity: qty, unit_price: unit }.merge(attrs) }
      visit.(van, Date.new(2026, 11, 10), work_to_do: "Brakes")
      visit.(van, Date.new(2026, 12, 20))
      visit.(coach, Date.new(2026, 10, 30), work_to_do: "Aircon")
      visit.(coach, Date.new(2026, 11, 5), status: "cancelled")
      visit.(van, Date.new(2026, 11, 1), status: "completed", odometer: 61_000, kind: "service",
                                         lines_attributes: [ line.("part", 2, 50), line.("labour", 1, 100) ])
      visit.(coach, Date.new(2026, 6, 15), status: "completed", odometer: 98_000, kind: "tyres", workshop: tyre_pro, gst_on: false,
                                           lines_attributes: [ line.("tyre", 2, 300, brand: "Michelin", model: "XZE", tyre_position: "Front Left", description: "295/80R22.5") ])
      visit.(coach, Date.new(2025, 10, 1), status: "completed", odometer: 80_000, lines_attributes: [ line.("part", 1, 999) ])
      { van:, coach: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  it "lists a tab with counts, search and the vehicle filter" do
    get api_v1_maintenance_visits_path, params: { tab: "upcoming" }
    expect(json[:data].pluck(:date)).to eq(%w[2026-11-10 2026-12-20])
    expect(json.dig(:meta, :counts)).to eq(upcoming: 2, to_record: 1, completed: 3, cancelled: 1)

    get api_v1_maintenance_visits_path, params: { tab: "completed" }
    expect(json[:data].pluck(:date)).to eq(%w[2026-11-01 2026-06-15 2025-10-01])
    expect(json[:data].first).to include(items_count: 2, has_invoice: false, total: "218.0")

    get api_v1_maintenance_visits_path, params: { tab: "upcoming", q: "brake" }
    expect(json[:data].size).to eq(1)
    get api_v1_maintenance_visits_path, params: { tab: "completed", q: "tyre pro" }
    expect(json[:data].pluck(:plate)).to eq(%w[PD2B])
    get api_v1_maintenance_visits_path, params: { tab: "completed", q: "tyres" }
    expect(json[:data].pluck(:date)).to eq(%w[2026-06-15])
    get api_v1_maintenance_visits_path, params: { tab: "completed", vehicle_id: f[:van].id }
    expect(json.dig(:meta, :counts)).to include(completed: 1, upcoming: 2)
  end

  it "gives the KPI tiles and the spend of the last 12 months with tyre changes" do
    get summary_api_v1_maintenance_visits_path
    d = json[:data]
    expect(d[:kpis]).to eq(next_30_days: 1, to_record: 1, spend_this_month: "218.0", last_12_months: "818.0", last_12_months_visits: 2)
    expect(d.dig(:spend, :total)).to eq("818.0")
    expect(d.dig(:spend, :by_type)).to eq([ { name: "Tyres", amount: "600.0", pct: 73 }, { name: "Labour", amount: "109.0", pct: 13 },
                                            { name: "Parts", amount: "109.0", pct: 13 } ]).or eq([ { name: "Tyres", amount: "600.0", pct: 73 },
                                                                                                   { name: "Parts", amount: "109.0", pct: 13 }, { name: "Labour", amount: "109.0", pct: 13 } ])
    expect(d.dig(:spend, :by_workshop).pluck(:name)).to eq([ "Tyre Pro Ubi", "Ah Huat Motor Works" ])
    expect(d.dig(:spend, :by_month)).to include("2026-06": "600.0", "2026-11": "218.0", "2025-12": "0.0")
    expect(d.dig(:spend, :by_month).size).to eq(12)
    expect(d.dig(:spend, :tyres)).to eq([ { date: "2026-06-15", plate: "PD2B", position: "Front Left", tyre: "Michelin XZE", size: "295/80R22.5",
                                           odometer: 98_000, quantity: "2.0", cost_each: "300.0", workshop: "Tyre Pro Ubi" } ])

    get summary_api_v1_maintenance_visits_path, params: { vehicle_id: f[:van].id }
    expect(json.dig(:data, :spend, :total)).to eq("218.0")
  end
end
