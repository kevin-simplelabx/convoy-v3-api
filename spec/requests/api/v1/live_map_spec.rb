require "rails_helper"

# Live Map: every bus now from its device's last report — on a trip (point reached, next point, ETA), available, offline
# (still on the map at its last position) — one bus with its device and stops, the runs of a day and a run's GPS track.
RSpec.describe "Live Map" do
  let(:company) { create(:company) }
  let(:now) { Time.zone.local(2026, 11, 2, 8, 20) }
  let!(:data) do
    within_tenant(company) do
      east = create(:vehicle_team, name: "East", color: "#008C95")
      bus = create(:vehicle, plate: "SBA3546A", seats: 29, make: "Mitsubishi", model: "Rosa", vehicle_team: east)
      parked = create(:vehicle, plate: "SLK4418D")
      gone = create(:vehicle, plate: "SLK0004A")
      lost = create(:vehicle, plate: "SLK7731E")
      create(:vehicle, plate: "PD9999Z") # no device: offline, not on the map
      trip = create(:trip, title: "MBC Shuttle", start_time: "08:00", end_time: "08:40")
      trip.stops.each_with_index { |s, i| s.update!(position: i.zero? ? 0 : 2, lat: i.zero? ? 1.3644 : 1.2745, lng: i.zero? ? 103.9915 : 103.7995) }
      trip.stops.create!(position: 1, name: "Labrador MRT", use: "pu", lat: 1.2722, lng: 103.8025)
      occ = TripOccurrence.create!(trip:, client: trip.client, date: now.to_date, start_time: 480, end_time: 520, starts_at: now.change(hour: 8),
                                   ends_at: now.change(hour: 8, min: 40), kind: "ad_hoc", trip_label: "TID000001", vehicle: bus, run_key: "r1",
                                   driver_name: "Tan Wei Ming", driver_phone: "+65 9123 4471")
      later = TripOccurrence.create!(trip:, client: trip.client, date: now.to_date, start_time: 600, end_time: 640, starts_at: now.change(hour: 10),
                                     ends_at: now.change(hour: 10, min: 40), kind: "ad_hoc", trip_label: "TID000002", vehicle: parked, run_key: "r2", slot_no: 2)
      occ.stop_events.create!(company_id: company.id, position: 0, arrived_at: now.change(hour: 8, min: 2), departed_at: now.change(hour: 8, min: 4), boarded: 6)
      devices = [ bus, parked, gone, lost ].map.with_index do |v, i|
        TrackingDevice.create!(vehicle: v, kind: i.zero? ? "gps_tracker" : "driver_app", name: i.zero? ? "OTW GPS T-8 tracker" : "Google Pixel 7")
      end
      ping = ->(d, at, lat, lng, speed = 0) { Telematics::Ping.call(device: d, at:, lat:, lng:, speed_kmh: speed, battery_pct: 80, gps_signal: "good", gsm_bars: 3) }
      ping.(devices[0], now - 60, 1.30, 103.85, 42)
      ping.(devices[0], now - 5, 1.28, 103.81, 38)
      ping.(devices[0], now - 30, 1.29, 103.83, 40) # late arrival: does not overwrite the newer report
      ping.(devices[1], now - 20, 1.36, 103.99)
      ping.(devices[2], now - 1.day, 1.35, 103.82)
      ping.(devices[3], now - 5.days, 1.35, 103.82)
      { bus:, parked:, gone:, lost:, occ:, later:, east: }
    end
  end

  before do
    travel_to now
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "lists every bus with its state, last report and the run it is on, with counts" do
    get api_v1_live_map_path
    expect(json[:meta][:counts]).to eq(on_trip: 1, available: 1, offline: 3)
    expect(json[:meta][:teams]).to eq([ { id: data[:east].id, name: "East", color: "#008C95" } ])
    rows = json[:data].index_by { |r| r[:plate] }
    bus = rows["SBA3546A"]
    expect(bus).to include(state: "on_trip", online: true, on_map: true, driver: { name: "Tan Wei Ming", phone: "+65 9123 4471" },
                           team: { id: data[:east].id, name: "East", color: "#008C95" }, device: { kind: "gps_tracker", name: "OTW GPS T-8 tracker" })
    expect(bus[:position]).to include(lat: 1.28, lng: 103.81, speed_kmh: 38)
    expect(bus[:run]).to include(trip_label: "TID000001", title: "MBC Shuttle", points: 3, points_done: 1)
    expect(bus[:run][:next_stop]).to include(number: 2, name: "Labrador MRT", at_stop: false)
    expect(bus[:run][:next_stop][:eta_at]).to be_present
    expect(rows["SLK4418D"]).to include(state: "available", run: nil)
    expect(rows["SLK4418D"][:next_run]).to include(trip_label: "TID000002")
    expect(rows["SLK0004A"]).to include(state: "offline", online: false, on_map: true)
    expect(rows["SLK7731E"]).to include(state: "offline", on_map: true)
    expect(rows["PD9999Z"]).to include(state: "offline", on_map: false, position: nil, device: nil)

    get api_v1_live_map_path, params: { state: "offline", q: "slk" }
    expect(json[:data].map { |r| r[:plate] }).to eq(%w[SLK0004A SLK7731E])
    get api_v1_live_map_path, params: { q: "tan wei" }
    expect(json[:data].map { |r| r[:plate] }).to eq(%w[SBA3546A])
  end

  it "shows one bus with its device and the stops of its run" do
    get api_v1_live_map_vehicle_path(data[:bus])
    d = json[:data]
    expect(d[:device]).to include(kind: "gps_tracker", sharing_enabled: true, report_interval_seconds: 10, battery_pct: 80, gps_signal: "good", gsm_bars: 3)
    expect(d[:run]).to include(on_board: 6)
    expect(d[:run][:stops].map { |s| [ s[:name], s[:state] ] })
      .to eq([ [ "Changi Airport T3", "done" ], [ "Labrador MRT", "current" ], [ "Marina Bay Sands", "upcoming" ] ])

    get api_v1_live_map_vehicle_path(data[:gone])
    expect(json[:data][:device]).to include(gps_signal: "none", gsm_bars: 0)
  end

  it "lists a bus's runs of a day and gives a run's GPS track (all, or after a time)" do
    get api_v1_live_map_vehicle_runs_path(data[:bus]), params: { date: "2026-11-02" }
    expect(json[:data]).to contain_exactly(hash_including(id: data[:occ].id, trip_label: "TID000001", points: 3))

    get api_v1_live_map_run_track_path(data[:occ])
    expect(json.dig(:data, :points).size).to eq(3)
    expect(json.dig(:data, :stops, 0)).to include(name: "Changi Airport T3", lat: 1.3644)

    get api_v1_live_map_run_track_path(data[:occ]), params: { since: (now - 40).iso8601 }
    expect(json.dig(:data, :points).map { |p| p[1] }).to eq([ 1.29, 1.28 ])
  end

  it "needs the vehicles or plans permission" do
    sign_in_as(create(:user, company:, permissions: %w[finance]))
    get api_v1_live_map_path
    expect(response).to have_http_status(:forbidden)
  end
end
