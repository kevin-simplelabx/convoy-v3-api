require "rails_helper"

# WebSocket for the Driver app and the Convoy App (Realtime, integration.md § WebSocket): the one-time ticket, what the
# server announces when a run changes (office, Sync, the driver, completion), new bell lines and alerts, bus positions, and
# the socket closing when the sign-in ends.
RSpec.describe "Realtime (WebSocket)" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:day) { Date.new(2026, 11, 3) }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      siti = create(:driver, name: "Siti", phone: "+6598765432")
      bus = create(:vehicle, plate: "PD3318K")
      bus.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      trip = create(:trip, start_time: "08:00", end_time: "09:00", starts_on: day)
      trip.stops.each_with_index { |s, i| s.update!(lat: i.zero? ? 1.333 : 1.2743, lng: i.zero? ? 103.7424 : 103.7973) }
      occ = TripOccurrence.create!(trip:, client: trip.client, date: day, start_time: 480, end_time: 540, starts_at: day.in_time_zone.change(hour: 8),
                                   ends_at: day.in_time_zone.change(hour: 9), kind: "ad_hoc", trip_label: "TID000001", vehicle: bus, driver: kumar, run_key: "r")
      { kumar:, siti:, bus:, trip:, occ: }
    end
  end
  let(:occ) { f[:occ] }
  let!(:token) { driver_token("91234567") }
  let(:account_id) { DriverAccount.find_by!(phone: "+6591234567").id }

  before { travel_to Time.zone.local(2026, 11, 3, 7, 50) }

  def runs_changed(*ids) = { type: "runs_changed", run_ids: ids, dates: [ "2026-11-03" ] }

  describe "tickets" do
    it "gives the Driver app a one-time ticket for its sign-in" do
      post api_v1_driver_app_cable_ticket_path, headers: as(token), as: :json
      expect(response).to have_http_status(:created)
      expect(json[:data]).to include(expires_in: 60, url: "/cable")
      expect(CableTicket.redeem(json.dig(:data, :ticket))).to eq(DriverJwt.find_by!(driver_account_id: account_id))

      post api_v1_driver_app_cable_ticket_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "gives the Convoy App one after Create Your Account" do
      bare = app_token(mobile: "9188 2045")
      post api_v1_convoy_app_cable_ticket_path, headers: app_as(bare), as: :json
      expect(json.dig(:error, :code)).to eq("profile_required")

      _, done = app_user(mobile: "9177 3301")
      post api_v1_convoy_app_cable_ticket_path, headers: app_as(done), as: :json
      expect(response).to have_http_status(:created)
      expect(CableTicket.redeem(json.dig(:data, :ticket))).to be_a(AppJwt)
    end
  end

  describe "a run changes" do
    it "tells the driver and the run's watchers when the office cancels it, and rings the bell" do
      sign_in_as(create(:user, :admin, company:))
      expect do
        patch cancel_api_v1_occurrence_path(occ.id), params: { lock_version: occ.lock_version }, as: :json
      end.to have_broadcasted_to("driver:#{account_id}").with(runs_changed(occ.id))
        .and have_broadcasted_to("driver:#{account_id}").with(type: "notifications_changed")
        .and have_broadcasted_to("run:#{occ.id}").with(type: "run_changed", run_id: occ.id)
      expect(response).to have_http_status(:ok)
    end

    it "tells both drivers when the run moves to another driver, not when the driver only opens it" do
      siti_account = DriverAccount.create!(phone: "+6598765432")
      within_tenant(company) { f[:siti].update!(driver_account: siti_account) }
      expect { within_tenant(company) { occ.update!(driver: f[:siti]) } }
        .to have_broadcasted_to("driver:#{account_id}").with(runs_changed(occ.id))
        .and have_broadcasted_to("driver:#{siti_account.id}").with(runs_changed(occ.id))
      expect { within_tenant(company) { occ.update!(driver_seen_at: Time.current) } }.not_to have_broadcasted_to("run:#{occ.id}")
    end

    it "tells the drivers of the runs Sync writes, and of the runs that completed" do
      trip = within_tenant(company) do
        create(:trip, start_time: "10:00", end_time: "11:00", starts_on: day, vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:bus].id } ])
      end
      expect { within_tenant(company) { Occurrences::Sync.call(trips: [ trip ], to: day) } }
        .to have_broadcasted_to("driver:#{account_id}").with(type: "runs_changed", run_ids: kind_of(Array), dates: [ "2026-11-03" ])

      travel_to Time.zone.local(2026, 11, 3, 9, 30)
      expect { within_tenant(company) { Occurrences::Complete.call } }
        .to have_broadcasted_to("driver:#{account_id}").with(runs_changed(occ.id))
    end

    it "tells the watchers when the driver starts, and sends the bus position to the screens that show it" do
      expect do
        post start_api_v1_driver_app_run_path(occ.id), params: { client_id: SecureRandom.uuid }, headers: as(token), as: :json
      end.to have_broadcasted_to("run:#{occ.id}").with(type: "run_changed", run_id: occ.id)

      now = Time.current
      points = [ { at: (now - 20).iso8601, lat: 1.30, lng: 103.80, heading: 80, speed_kmh: 40 }, { at: (now - 10).iso8601, lat: 1.31, lng: 103.79, heading: 90, speed_kmh: 42.4 } ]
      expect { post api_v1_driver_app_positions_path, params: { points: }, headers: as(token), as: :json }
        .to have_broadcasted_to("run:#{occ.id}:position").exactly(:once)
        .with(type: "position", run_id: occ.id, lat: 1.31, lng: 103.79, heading: 90.0, speed_kmh: 42, recorded_at: (now - 10).iso8601)
    end
  end

  it "tells the Convoy App person about new alerts" do
    account, = app_user(mobile: "9188 2045")
    rows = [ { app_account_id: account.id, kind: "bill_issued", title: "New bill", body: "Term 4", dedupe_key: "bill-1" } ]
    expect { ConvoyApp::Alerts.write(rows) }.to have_broadcasted_to("app:#{account.id}").with(type: "alerts_changed")
    expect { ConvoyApp::Alerts.write(rows) }.not_to have_broadcasted_to("app:#{account.id}") # already there
  end

  it "closes the socket of a sign-in that ended" do
    jwt = DriverJwt.find_by!(driver_account_id: account_id)
    expect { delete api_v1_driver_app_session_path, headers: as(token), as: :json }
      .to have_broadcasted_to("action_cable/#{jwt.to_gid_param}").with(type: "disconnect", reconnect: false)
  end
end
