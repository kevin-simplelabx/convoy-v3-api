require "rails_helper"

# Convoy Driver app GPS: a batch of points on the trip on the road (the phone becomes the bus's tracking device; Live Map
# sees it; an older batch does not overwrite the last report), nothing stored without a bus, the server confirming the
# arrival (slow inside 30 m, or 15 s inside; not when passing), the phone's geofence alert, and the GPS profile.
RSpec.describe "Driver app GPS" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:day) { Date.new(2026, 11, 3) }
  let(:stop) { [ 1.3330, 103.7424 ] }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      spare = create(:driver, name: "Siti", phone: "+6598765432")
      bus = create(:vehicle, plate: "PD3318K")
      bus.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      trip = create(:trip, start_time: "08:00", end_time: "09:00", starts_on: day)
      trip.stops.each_with_index { |s, i| s.update!(lat: i.zero? ? stop[0] : 1.2743, lng: i.zero? ? stop[1] : 103.7973) }
      occ = TripOccurrence.create!(trip:, client: trip.client, date: day, start_time: 480, end_time: 540, starts_at: day.in_time_zone.change(hour: 8),
                                   ends_at: day.in_time_zone.change(hour: 9), kind: "ad_hoc", trip_label: "TID000001", vehicle: bus, driver: kumar, run_key: "r")
      { kumar:, spare:, bus:, occ: }
    end
  end
  let(:occ) { f[:occ] }

  before { travel_to Time.zone.local(2026, 11, 3, 7, 50) }

  def point(at, lat, lng, speed = 40, **extra) = { at: at.iso8601, lat:, lng:, speed_kmh: speed, heading: 90, **extra }
  def metres_north(m) = stop[0] + (m / 111_320.0)

  def send_points(token, *points)
    post api_v1_driver_app_positions_path, params: { points: }, headers: as(token), as: :json
    json
  end

  def start(token)
    post start_api_v1_driver_app_run_path(occ.id), params: { client_id: SecureRandom.uuid }, headers: as(token), as: :json
    expect(response).to have_http_status(:ok), json.inspect
  end

  def arrived_at = within_tenant(company) { occ.stop_events.reload.find_by(position: 0)&.arrived_at }

  it "records a batch on the trip on the road as the phone's device, for Live Map" do
    token = driver_token("91234567")
    start(token)
    now = Time.current
    send_points(token, point(now - 20, 1.30, 103.80, accuracy_m: 8, battery_pct: 77), point(now - 10, 1.31, 103.79, accuracy_m: 35))
    expect(json[:data]).to eq(recorded: 2, run_id: occ.id, vehicle: { id: f[:bus].id, plate: "PD3318K" }, arrived: [])
    send_points(token, point(now - 60, 1.29, 103.81)) # an older batch, sent late after being offline
    within_tenant(company) do
      expect(occ.positions.count).to eq(3)
      live = f[:bus].reload.live_position
      expect(live).to have_attributes(lat: 1.31, gps_signal: "fair", occurrence_id: occ.id, recorded_at: now - 10)
      expect(live.tracking_device).to have_attributes(kind: "driver_app", identifier: "driver_app:#{DriverAccount.last.id}")
      expect(DriverAppSession.last).to have_attributes(tracking_device_id: live.tracking_device_id, last_seen_at: be_present)
    end

    sign_in_as(create(:user, :admin, company:))
    get api_v1_live_map_path
    expect(json[:data].find { it[:plate] == "PD3318K" }).to include(state: "on_trip")
  end

  it "stores nothing for a driver on no bus today, and checks the points" do
    token = driver_token("98765432")
    send_points(token, point(Time.current, 1.3, 103.8))
    expect(json[:data]).to include(recorded: 0, vehicle: nil)

    token = driver_token("91234567")
    send_points(token, { at: "soon", lat: 1.3, lng: 103.8 })
    expect(json.dig(:error, :message)).to eq("Each point needs at (ISO 8601), lat and lng")
    send_points(token, *Array.new(501) { point(Time.current, 1.3, 103.8) })
    expect(json.dig(:error, :message)).to eq("Send 500 points at most")
  end

  it "confirms the arrival when slow inside the circle or inside for 15 s, not when driving past" do
    token = driver_token("91234567")
    start(token)
    travel_to Time.current + 2.minutes
    t = Time.current - 2.minutes # points sent a little after the fact
    send_points(token, point(t, metres_north(20), stop[1], 45), point(t + 4, metres_north(-25), stop[1], 42)) # drove past in the next lane
    expect(json.dig(:data, :arrived)).to eq([])
    send_points(token, point(t + 30, metres_north(60), stop[1], 3)) # slow but 60 m away
    expect(arrived_at).to be_nil

    send_points(token, point(t + 60, metres_north(15), stop[1], 12), point(t + 70, metres_north(10), stop[1], 9), point(t + 80, metres_north(8), stop[1], 8))
    expect(json.dig(:data, :arrived)).to eq([ 0 ])
    expect(arrived_at).to eq(t + 60)

    post arrive_api_v1_driver_app_run_path(occ.id), params: { client_id: SecureRandom.uuid, position: 0, at: (t + 90).iso8601 }, headers: as(token), as: :json
    expect(arrived_at).to eq(t + 60) # the first arrival stays
  end

  it "takes the phone's geofence alert: enter starts the clock, a slow bus arrives at once, exit before arriving is a pass-by" do
    token = driver_token("91234567")
    start(token)
    t = Time.current
    send_points(token, point(t, 1.30, 103.80, 40))
    post geofence_api_v1_driver_app_run_path(occ.id), params: { position: 0, event: "enter", at: (t + 5).iso8601 }, headers: as(token), as: :json
    expect(json[:data]).to include(position: 0, arrived_at: nil, entered_at: be_present)
    post geofence_api_v1_driver_app_run_path(occ.id), params: { position: 0, event: "exit", at: (t + 9).iso8601 }, headers: as(token), as: :json
    expect(json[:data]).to include(entered_at: nil, exited_at: be_present)

    travel_to t + 20
    send_points(token, point(t + 18, metres_north(5), stop[1], 2))
    post geofence_api_v1_driver_app_run_path(occ.id), params: { position: 0, event: "enter", at: (t + 20).iso8601 }, headers: as(token), as: :json
    expect(json.dig(:data, :arrived_at)).to be_present

    post geofence_api_v1_driver_app_run_path(occ.id), params: { position: 0, event: "wave" }, headers: as(token), as: :json
    expect(json.dig(:error, :message)).to eq("event must be enter or exit")
  end

  it "gives the GPS profile and the reason lists" do
    token = driver_token("91234567")
    get api_v1_driver_app_config_path, headers: as(token)
    expect(json.dig(:data, :gps)).to include(interval_seconds: 5, distance_filter_m: 10, heartbeat_seconds: 300, geofence_radius_m: 30)
    expect(json[:data]).to include(start_early_minutes: 60, late_warning_minutes: 30, time_format: "24")
    expect(json.dig(:data, :reasons, :force_end)).to include("Vehicle breakdown")
  end
end
