require "rails_helper"

# Ops Control: runs with a first pick-up in the next 2 hours checked against the rules (driver app, not started, ETA,
# late arrival, GPS), alerts kept (raised, escalated after 3 min, acknowledged, cleared), KPIs, banner and the Alert Log.
RSpec.describe "Ops Control" do
  let(:company) { create(:company) }
  let(:now) { Time.zone.local(2026, 11, 2, 8, 0) }
  let(:pickup) { [ 1.3000, 103.8000 ] }
  let!(:data) do
    within_tenant(company) do
      trip = create(:trip, title: "WEN Shuttle", start_time: "07:00", end_time: "09:00")
      trip.stops.each_with_index { |s, i| s.update!(lat: i.zero? ? pickup[0] : 1.35, lng: i.zero? ? pickup[1] : 103.85) }
      run = lambda do |n, plate, start, started: nil, signed_in: true|
        bus = create(:vehicle, plate:)
        driver = create(:driver, name: "Driver #{plate}")
        DriverAppSession.create!(driver:, signed_in_at: now - 2.hours) if signed_in
        occ = TripOccurrence.create!(trip:, client: trip.client, date: now.to_date, start_time: (start.hour * 60) + start.min, end_time: 600,
                                     starts_at: start, ends_at: now.change(hour: 10), kind: "ad_hoc", trip_label: "TID00000#{n}",
                                     vehicle: bus, driver:, run_key: "r#{n}", slot_no: n, started_at: started)
        { bus:, occ:, device: TrackingDevice.create!(vehicle: bus, kind: "gps_tracker", name: "Tracker") }
      end
      ping = ->(r, at, lat, lng) { Telematics::Ping.call(device: r[:device], at:, lat:, lng:) }

      waiting = run.(1, "SBA0001A", now + 10.minutes, signed_in: false)  # not logged in, not started, 300 m away
      ping.(waiting, now - 10, pickup[0] + 0.0027, pickup[1])
      far = run.(2, "SBA0002B", now + 5.minutes, started: now - 10.minutes) # started, 10 km away → ETA 20+ min late
      ping.(far, now - 10, pickup[0] + 0.09, pickup[1])
      late = run.(3, "SBA0003C", now - 10.minutes, started: now - 20.minutes) # reached the pick-up 5 min late
      late[:occ].stop_events.create!(company_id: company.id, position: 0, arrived_at: now - 5.minutes)
      ping.(late, now - 10, pickup[0], pickup[1])
      lost = run.(4, "SBA0004D", now - 30.minutes, started: now - 40.minutes) # on time, then no GPS for 7 min
      lost[:occ].stop_events.create!(company_id: company.id, position: 0, arrived_at: now - 30.minutes, departed_at: now - 29.minutes)
      ping.(lost, now - 7.minutes, 1.32, 103.82)
      later = run.(5, "SBA0005E", now + 90.minutes) # fine for now
      ping.(later, now - 10, pickup[0], pickup[1])
      { waiting:, far:, late:, lost:, later: }
    end
  end

  before do
    travel_to now
    sign_in_as(create(:user, company:, name: "Nur Aisyah", permissions: %w[vehicles]))
  end

  def rows = json.dig(:data, :rows).index_by { |r| r[:plate] }

  it "checks every run against the rules, with KPIs, counts and the banner" do
    get api_v1_ops_control_path, params: { tab: "all" }
    expect(json[:meta]).to include(duty: "Nur Aisyah")
    expect(json.dig(:meta, :rules)).to include(login_minutes: [ 20, 10 ], escalate_after_minutes: 3)
    r = rows
    expect(r["SBA0001A"]).to include(state: "action_now", severity: 2)
    expect(r["SBA0001A"][:app]).to include(status: "not_logged_in")
    expect(r["SBA0001A"][:alerts].map { |a| [ a[:kind], a[:severity] ] }).to eq([ [ "login", 2 ], [ "start", 1 ] ])
    expect(r["SBA0001A"][:alerts].last[:message]).to eq("Trip not started. First pick-up in 10 min. Driver is 300 m away but has not started")
    expect(r["SBA0001A"][:gps]).to include(status: "to_first_pickup", distance_m: 300)
    expect(r["SBA0002B"][:alerts].map { |a| a[:kind] }).to eq(%w[eta])
    expect(r["SBA0002B"][:eta][:late_minutes]).to be > 5
    expect(r["SBA0003C"]).to include(state: "at_risk", arrived_at: be_present)
    expect(r["SBA0003C"][:alerts].first[:message]).to eq("Reached first pick-up 5 min late")
    expect(r["SBA0004D"][:alerts].first).to include(kind: "gps", severity: 2, message: "No GPS for 7 min")
    expect(r["SBA0004D"][:gps][:status]).to eq("no_signal")
    expect(r["SBA0005E"]).to include(state: "ready", alerts: [])

    d = json[:data]
    expect(d[:counts]).to eq(needs_action: 4, all: 5, not_started: 2, running: 3, ended: 0)
    expect(d[:kpis]).to include(next_2_hours: 3, running: 3, action_now: 3, at_risk: 1, unacknowledged: 3, started_today: 2,
                                on_time_count: 1, late_today: 1, on_time_today: 50)
    expect(d[:banner]).to include(count: 3, more: 0)
    expect(d[:banner][:trips].first).to include(plate: "SBA0004D", escalated: false)

    get api_v1_ops_control_path
    expect(json.dig(:data, :rows).size).to eq(4)
    get api_v1_ops_control_path, params: { tab: "all", q: "sba0005" }
    expect(json.dig(:data, :rows).map { |x| x[:plate] }).to eq(%w[SBA0005E])
  end

  it "escalates unacknowledged action alerts, acknowledges a trip and logs alerts until they clear" do
    get api_v1_ops_control_path
    travel 4.minutes
    get api_v1_ops_control_path
    expect(json.dig(:data, :banner, :trips).map { |t| t[:escalated] }).to all(be(true))

    occ = data[:waiting][:occ]
    post api_v1_ops_control_acknowledge_path(occ)
    expect(json[:data]).to include(acknowledged: 2, by: "Nur Aisyah")
    post api_v1_ops_control_acknowledge_path(occ)
    expect(response).to have_http_status(:unprocessable_content)

    get api_v1_ops_control_path
    row = rows["SBA0001A"]
    expect(row).to include(state: "action_now", can_acknowledge: false, acknowledged: hash_including(by: "Nur Aisyah"))
    expect(json.dig(:data, :banner, :trips).map { |t| t[:plate] }).not_to include("SBA0001A")

    within_tenant(company) do
      DriverAppSession.create!(driver: occ.driver, signed_in_at: Time.current)
      Occurrences::DriverProgress.call(occ, :start)
      occ.stop_events.create!(company_id: company.id, position: 0, arrived_at: Time.current)
      Telematics::Ping.call(device: data[:waiting][:device], at: Time.current, lat: pickup[0], lng: pickup[1])
    end
    get api_v1_ops_control_path, params: { tab: "all" }
    expect(rows["SBA0001A"]).to include(state: "on_route", alerts: [])

    get api_v1_ops_control_log_path
    statuses = json[:data].select { |a| a[:plate] == "SBA0001A" }.map { |a| [ a[:kind], a[:status] ] }
    expect(statuses).to contain_exactly(%w[login cleared], %w[start cleared])
    expect(json[:data].find { |a| a[:plate] == "SBA0004D" }).to include(status: "escalated", kind: "gps")
  end

  it "shows the open alerts on the Dashboard" do
    sign_in_as(create(:user, :admin, company:))
    get api_v1_dashboard_path, params: { widgets: %w[alerts] }
    expect(json.dig(:data, :widgets, :alerts)).to include(available: true, count: 4, action: 3, at_risk: 1)
  end

  it "needs the vehicles or plans permission" do
    sign_in_as(create(:user, company:, permissions: %w[finance]))
    get api_v1_ops_control_path
    expect(response).to have_http_status(:forbidden)
  end
end
