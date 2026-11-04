require "rails_helper"

# Dashboard: widgets by permission, the user's layout saved on the server, and the figures of each widget.
RSpec.describe "Dashboard" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      google = create(:client, name: "Google")
      bus = create(:vehicle, plate: "PC7475L", seats: 23, coe_expires_on: Date.new(2026, 12, 1))
      trip = create(:trip, client: google, title: "Shuttle")
      [ [ 0, 2 ], [ 1, 9 ], [ 2, nil ] ].each do |i, delay|
        date = Date.new(2026, 11, 2)
        TripOccurrence.create!(trip:, client: google, date:, start_time: 420 + (i * 60), end_time: 480 + (i * 60), starts_at: date.in_time_zone.change(hour: 7 + i),
                               ends_at: date.in_time_zone.change(hour: 8 + i), kind: "ad_hoc", trip_label: "T#{i}", vehicle: i == 2 ? nil : bus, price: 100,
                               run_key: "k#{i}", slot_no: i + 1, status: i == 2 ? "scheduled" : "completed", max_delay_minutes: delay)
      end
      MaintenanceVisit.create!(vehicle: bus, workshop: Workshop.create!(name: "Ah Huat Motor Works"), date: Date.new(2026, 11, 2), kind: "repair", work_to_do: "Brakes", start_time: "10:00", end_time: "12:00")
      { google:, bus: }
    end
  end

  before { travel_to Time.zone.local(2026, 11, 2, 8, 30) }

  it "shows widgets by permission and keeps the layout on the server" do
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
    get api_v1_dashboard_widgets_path
    keys = json.dig(:data, :widgets).pluck(:key)
    expect(keys).to include("otp", "docs", "clotp")
    expect(keys).not_to include("rev", "profit", "opp")

    get api_v1_dashboard_layout_path
    expect(json[:data]).to include(saved: false, period: "d7", page: 0)
    expect(json.dig(:data, :pages, 0, :items, 0)).to eq(widget: "otp", x: 0, y: 0, cols: 4, rows: 2)
    patch api_v1_dashboard_layout_path, params: { period: "d30" }, as: :json # picking a period keeps it
    expect(json[:data]).to include(saved: true, period: "d30", page: 0)
    patch api_v1_dashboard_layout_path, params: { period: "year" }, as: :json
    expect(json.dig(:error, :details)).to have_key(:period)

    put api_v1_dashboard_layout_path, params: { pages: [ { name: "Mine", items: [ { widget: "docs", x: 0, y: 0, cols: 2, rows: 2 }, { widget: "profit", x: 2, y: 0, cols: 4, rows: 3 } ] } ] }, as: :json
    expect(json[:data]).to include(saved: true)
    expect(json.dig(:data, :pages, 0, :items).map { |i| i[:widget] }).to eq(%w[docs]) # profit needs vehfin
    put api_v1_dashboard_layout_path, params: { pages: [ { name: "Bad", items: [ { widget: "docs", x: 7, y: 0, cols: 2, rows: 2 } ] } ] }, as: :json
    expect(json.dig(:error, :details, :pages)).to eq([ "Pages Page 1 has a widget out of the grid" ])

    delete api_v1_dashboard_layout_path
    expect(json[:data]).to include(saved: false)
  end

  it "works out the widgets from the runs of the period" do
    sign_in_as(create(:user, :admin, company:))
    get api_v1_dashboard_path, params: { period: "today" }
    w = json.dig(:data, :widgets)
    expect(w[:otp]).to include(available: true, value: 50.0, runs: 2, on_time: 1, allowance: 5)
    expect(w[:late]).to include(count: 1, series: [ { date: "2026-11-02", count: 1 } ])
    expect(w[:today]).to include(total: 3, completed: 2, scheduled: 1, running: 0, still_to_run: 1, average_a_day: 3,
                                 busiest: { date: "2026-11-02", count: 3 }, by_client: [ { client_id: data[:google].id, name: "Google", runs: 3 } ])
    expect(w[:unas]).to include(count: 1)
    expect(w[:unas][:list].sole).to include(title: "Shuttle", missing: "both")
    expect(w[:off][:list]).to eq([ { vehicle_id: data[:bus].id, plate: "PC7475L", reason: "Maintenance: Brakes", kind: "Repair", back_on: "2026-11-03" } ])
    expect(w[:alerts][:period]).to eq(raised: 0, escalated: 0, avg_ack_seconds: nil)
    expect(w[:profit]).to include(ytd: be_present, vehicles: [ hash_including(plate: "PC7475L") ])
    expect(w[:rev][:month]).to include(:revenue, :cost, :profit)
    expect(w[:opp]).to include(waiting_operators: 0, approved_unpaid_batches: 0)
    expect(w[:rev]).to include(value: "300.0")
    expect(w[:docs][:list]).to eq([ { vehicle_id: data[:bus].id, plate: "PC7475L", document: "COE", expires_on: "2026-12-01" } ])
    expect(w[:clotp][:clients]).to eq([ { client_id: data[:google].id, name: "Google", runs: 2, on_time: 50.0, change: nil } ])
    expect(w[:clrisk][:list].sole).to include(name: "Google", badge: "Below Target", on_time: 50.0)
    expect(w[:clrisk]).to include(count: 1)
    expect(w[:alerts]).to include(available: true, note: "Live, so the period does not change it")
    expect(w[:coll]).to include(available: true, bills: 0, billed: "0.0", overdue: "0.0", overdue_bills: 0)
    expect(w[:noshow]).to eq(available: false, reason: "No-shows are not recorded yet")
    expect(w[:profit]).to include(available: true)
  end
end
