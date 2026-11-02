require "rails_helper"

# Fuel & Energy: Needs a Look (alerts with Mark Checked), the KPI row and the Usage card.
RSpec.describe "Fuel insights" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      van = create(:vehicle, plate: "PD1A", seats: 13)
      van2 = create(:vehicle, plate: "PD2B", seats: 13)
      tan = create(:driver, name: "Tan")
      lim = create(:driver, name: "Lim")
      van.driver_schedules.create!(driver: tan, starts_on: Date.new(2026, 1, 1))
      van2.driver_schedules.create!(driver: lim, starts_on: Date.new(2026, 1, 1))
      esso = FuelCompany.create!(name: "Esso")
      { van:, van2:, tan:, lim:, esso: }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 20, 9, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  # Fills every 5 days, 450 km apart, 50 L (9 km/L) at S$2.60/L, then unusual ones on PD1A.
  def log!
    within_tenant(company) do
      [ f[:van], f[:van2] ].each_with_index do |bus, b|
        odo = 10_000
        (0..14).each do |n|
          FuelEntry.create!(vehicle: bus, date: Date.new(2026, 9, 1) + (n * 5), time: "08:00", kind: "diesel", quantity: 50,
                            cost: 130, odometer: odo, fuel_company: b.zero? ? f[:esso] : nil)
          odo += 450
        end
      end
      last = FuelEntry.where(vehicle: f[:van]).latest_first.first
      FuelEntry.create!(vehicle: f[:van], date: last.date, time: "10:00", kind: "diesel", quantity: 20, cost: 75, odometer: last.odometer + 30, full: false)
      FuelEntries::Recompute.call(vehicle: f[:van])
      FuelEntries::Recompute.call(vehicle: f[:van2])
      FuelAlerts::Scan.call
    end
  end

  it "finds unusual fills and keeps Mark Checked through a rescan" do
    log!
    get api_v1_fuel_alerts_path
    expect(json.dig(:meta, :counts)).to eq(open: 2, checked: 0)
    expect(json[:data].pluck(:kind)).to contain_exactly("dbl", "price")
    dbl = json[:data].find { |a| a[:kind] == "dbl" }
    expect(dbl).to include(plate: "PD1A", message: "Two fills 30 km apart (50 L, then 20 L)", tone: "warn")
    price = json[:data].find { |a| a[:kind] == "price" }
    expect(price[:message]).to eq("Paid S$3.75 per L, 44% above the usual S$2.60")

    patch check_api_v1_fuel_alert_path(dbl[:id])
    expect(json[:data]).to include(status: "checked", checked_by: be_present)
    within_tenant(company) { FuelAlerts::Scan.call }
    get api_v1_fuel_alerts_path, params: { status: "checked" }
    expect(json[:data].pluck(:id)).to eq([ dbl[:id] ])

    patch reopen_api_v1_fuel_alert_path(dbl[:id])
    expect(json[:data][:status]).to eq("open")

    # Deleting the fill removes what was found on it
    delete api_v1_fuel_entry_path(dbl[:fuel_entry_id])
    get api_v1_fuel_alerts_path
    expect(json[:data]).to be_empty
  end

  it "flags efficiency far off the usual and an odometer typed lower" do
    within_tenant(company) do
      odo = 10_000
      (0..5).each do |n|
        km = n == 4 ? 900 : 450
        odo += km
        FuelEntry.create!(vehicle: f[:van], date: Date.new(2026, 11, 1) + n, kind: "diesel", quantity: 50, cost: 130, odometer: odo)
      end
      FuelEntry.create!(vehicle: f[:van], date: Date.new(2026, 11, 8), kind: "diesel", quantity: 50, cost: 130, odometer: odo - 1000)
      FuelEntries::Recompute.call(vehicle: f[:van])
      FuelAlerts::Scan.call
    end
    get api_v1_fuel_alerts_path
    messages = json[:data].pluck(:message)
    expect(messages).to include("18 km/L, 100% better than usual. A fill may not have been recorded",
                                "Odometer 12,150 km is lower than the last reading of 13,150 km")
  end

  it "gives the KPI row of a month" do
    log!
    get api_v1_fuel_kpis_path, params: { month: "2026-09" }
    expect(json[:data]).to include(spend: "1560.0", fuel_litres: "600.0", fills: 12, fuel_efficiency: "9.0", km: 4500,
                                   cost_per_km: "0.35", spend_before: "0.0", spend_change_pct: nil)
  end

  it "shows usage against the period before, by vehicle and by driver, with a summary" do
    log!
    get api_v1_fuel_usage_path, params: { measure: "spend", range: "12m" }
    d = json[:data]
    expect(d).to include(by: "month", total: "3975.0", better: "lower", zoomed: false)
    expect(d[:buckets].size).to eq(12)
    expect(d[:buckets].last).to include(from: "2026-11-01", current: "595.0")
    expect(d.dig(:summary, :title)).to eq("Worth a Look")

    get api_v1_fuel_usage_path, params: { measure: "eff", range: "12m", view: "vehicle" }
    expect(json.dig(:data, :rows).map { |r| r.slice(:name, :current, :alerts) })
      .to contain_exactly({ name: "PD1A", current: "8.2", alerts: 2 }, { name: "PD2B", current: "8.4", alerts: 0 })

    get api_v1_fuel_usage_path, params: { measure: "fuel", view: "company", key: "none", zoom_from: "2026-11-01", zoom_to: "2026-11-30" }
    expect(json[:data]).to include(by: "day", zoomed: true, total: "120.0", before: { from: "2026-10-01", to: "2026-10-31" })
    expect(json.dig(:data, :buckets).size).to eq(30)

    get api_v1_fuel_usage_path, params: { measure: "eff", view: "driver", range: "12w" }
    expect(json.dig(:data, :drivers).pluck(:name)).to contain_exactly("Tan", "Lim")
  end
end
