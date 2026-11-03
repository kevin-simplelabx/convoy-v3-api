require "rails_helper"

# Reports > Shuttle Report: utilisation, riders, on-time per stop (with the client's allowance), stop activity, trend,
# and the month grids, from recorded stop events (corrected values first).
RSpec.describe "Shuttle report" do
  let(:company) { create(:company) }
  let!(:data) do
    within_tenant(company) do
      google = create(:client, name: "Google", on_time_allowance: 3)
      bus = create(:vehicle, plate: "PC7475L", seats: 20)
      trip = create(:trip, client: google, title: "MBC Shuttle", start_time: "08:00", end_time: "08:30")
      trip.update_columns(kind: "corporate_shuttle") # rubocop:disable Rails/SkipsModelValidations
      trip.stops.each_with_index { |s, i| s.update!(position: i == 0 ? 0 : 2, scheduled_time: i == 0 ? "08:00" : "08:30") }
      trip.stops.create!(position: 1, name: "Labrador MRT", use: "pu", scheduled_time: "08:15")
      make = ->(date, arrive, boarded) do
        occ = TripOccurrence.create!(trip:, client: google, date:, start_time: 480, end_time: 510, starts_at: date.in_time_zone.change(hour: 8),
                                     ends_at: date.in_time_zone.change(hour: 8, min: 30), kind: "corporate_shuttle", trip_label: "S-#{date.day}",
                                     vehicle: bus, run_key: "r#{date}", status: "completed")
        arrive.each_with_index do |m, i|
          at = date.in_time_zone.change(hour: 8) + (m - 480).minutes
          occ.stop_events.create!(company_id: company.id, position: i, arrived_at: at, departed_at: at + 1.minute, boarded: boarded[i])
        end
        occ
      end
      { trip:, google:,
        runs: [ make.(Date.new(2026, 10, 5), [ 480, 495, 510 ], [ 8, 4, 0 ]),   # all on time: 12 riders
                make.(Date.new(2026, 10, 6), [ 480, 501, 520 ], [ 6, 2, 0 ]),   # Labrador 6 late, MBC 10 late
                make.(Date.new(2026, 9, 7), [ 480, 495, 510 ], [ 5, 0, 0 ]) ] }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
  end

  it "lists clients with shuttle routes and the periods" do
    get api_v1_reports_shuttle_options_path
    expect(json.dig(:data, :clients, 0)).to include(name: "Google", on_time_allowance: 3, routes: [ hash_including(id: data[:trip].id, title: "MBC Shuttle") ])
    expect(json.dig(:data, :periods, 0)).to eq(value: "m|2026-10", label: "October 2026")
  end

  it "works out the month's KPIs against the month before, timings, stop activity and the trend" do
    get api_v1_reports_shuttle_path, params: { trip_id: data[:trip].id, period: "m|2026-10" }
    d = json[:data]
    expect(d[:kpis]).to include(riders: 20, riders_change: 15, service_days: 2, runs: 2, utilisation: 50.0, on_time: 66.7, seats: 20)
    expect(d[:timings].first).to include(dep: "08:00", riders: 20, avg: 10.0, max: 12)
    expect(d[:stop_activity].first[:stops]).to eq([ { name: "Changi Airport T3", boarded: 14, pct: 70.0 }, { name: "Labrador MRT", boarded: 6, pct: 30.0 } ])
    expect(d[:trend].last).to include(month: "2026-10", riders: 20, in_period: true)

    get api_v1_reports_shuttle_grid_path, params: { trip_id: data[:trip].id, month: "2026-10" }
    g = json[:data]
    expect(g[:on_time]).to include(ok: 4, late: 2, early: 0, skip: 0, pct: 66.7)
    expect(g[:rows].first[:cells].map { |c| c[:riders] }).to eq([ 12, 8 ])
    expect(g[:rows].first[:on_time].last[:stops].map { |s| s[:status] }).to eq(%w[ok late late])
    expect(g[:worst_day]).to eq("2026-10-06")
  end

  it "uses corrected values from Correct Record" do
    run = data[:runs].second
    post api_v1_trip_history_correction_path(run.id), params: { correction: { stops: [ { position: 1, arrived_at: "08:16", boarded: 3 } ], reason: "GPS lag" } }, as: :json
    expect(response).to have_http_status(:ok), json.inspect
    get api_v1_reports_shuttle_grid_path, params: { trip_id: data[:trip].id, month: "2026-10" }
    cell = json.dig(:data, :rows, 0, :on_time).last
    expect(cell[:stops].second).to include(status: "ok", arrived: "08:16", amended: true)
  end
end
