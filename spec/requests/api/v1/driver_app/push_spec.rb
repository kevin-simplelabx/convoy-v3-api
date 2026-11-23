require "rails_helper"

# Convoy Driver app › push (API-ISSUES #18): the phone's token goes with the sign-in; every new bell line, from any company
# the driver works for, is pushed to it once (pushed_at), with what a tap opens; a token Firebase no longer knows is dropped.
RSpec.describe "Driver app push" do
  include ActiveJob::TestHelper

  let(:company) { create(:company, name: "SimpleDrive") }
  let(:other) { create(:company, name: "Eastern Coaches") }
  let!(:kumar) { within_tenant(company) { create(:driver, name: "Kumar", phone: "+6591234567") } }
  let(:body) { { device: { platform: "android", push_token: "fcm-kumar" } } }

  before { travel_to Time.zone.local(2026, 11, 3, 6, 0) }

  def register(token, push_token = "fcm-kumar")
    put api_v1_driver_app_device_path, params: { device: { platform: "android", push_token: } }, headers: as(token), as: :json
    expect(response).to have_http_status(:no_content)
  end

  def bell_line(member, **attrs)
    within_tenant(member.company) do
      DriverNotification.create!(company: member.company, **DriverNotification.member_key(member), kind: "notice", title: "Gate closed",
                                 body: "Drop off at the main gate.", **attrs)
    end
  end

  describe "the device token" do
    it "is registered with this sign-in, replaced, moved to another sign-in, and removed" do
      token = driver_token("91234567")
      register(token)
      account = kumar.reload.driver_account
      expect(DriverDevice.all.map { [ it.driver_account_id, it.platform, it.push_token ] }).to eq([ [ account.id, "android", "fcm-kumar" ] ])

      put api_v1_driver_app_device_path, params: { platform: "ios", push_token: "fcm-kumar-2" }, headers: as(token), as: :json
      expect(DriverDevice.pluck(:platform, :push_token)).to eq([ %w[ios fcm-kumar-2] ])

      siti = within_tenant(company) { create(:driver, phone: "+6598765432") }
      register(driver_token("98765432"), "fcm-kumar-2")
      expect(DriverDevice.pluck(:driver_account_id)).to eq([ siti.reload.driver_account_id ])

      register(token, "fcm-kumar")
      delete api_v1_driver_app_device_path, headers: as(token)
      expect(response).to have_http_status(:no_content)
      expect(DriverDevice.where(push_token: "fcm-kumar")).to be_empty
    end

    it "goes with the sign-in: Sign Out and a sign-in on another phone remove it" do
      token = driver_token("91234567")
      register(token)
      delete api_v1_driver_app_session_path, headers: as(token)
      expect(DriverDevice.count).to eq(0)

      register(driver_token("91234567"))
      driver_token("91234567")
      expect(DriverDevice.count).to eq(0)
    end

    it "refuses an unknown platform and a missing token" do
      token = driver_token("91234567")
      put api_v1_driver_app_device_path, params: { device: { platform: "web", push_token: "x" } }, headers: as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      put api_v1_driver_app_device_path, params: { device: { platform: "ios" } }, headers: as(token), as: :json
      expect(response.status).to be_in([ 400, 422 ])
    end
  end

  describe "pushes" do
    it "sends each new bell line once, from every company, with what a tap opens" do
      register(driver_token("91234567"))
      eastern = within_tenant(other) { create(:driver, phone: "+6591234567", driver_account: kumar.reload.driver_account) }

      perform_enqueued_jobs do
        bell_line(kumar)
        bell_line(eastern, kind: "vehicle_switch", title: "Vehicle switch today", body: "Switch to PD4472H from 06:30 today.")
      end
      lines = DriverNotification.unscoped.order(:id).to_a
      expect(fake_push.sent).to eq([
        { token: "fcm-kumar", title: "Gate closed", body: "Drop off at the main gate.",
          data: { type: "driver_notification", id: lines[0].id.to_s, kind: "notice", company_id: company.id.to_s, membership: "driver-#{kumar.id}" } },
        { token: "fcm-kumar", title: "Vehicle switch today", body: "Switch to PD4472H from 06:30 today.",
          data: { type: "driver_notification", id: lines[1].id.to_s, kind: "vehicle_switch", company_id: other.id.to_s, membership: "driver-#{eastern.id}" } }
      ])
      expect(lines.map(&:pushed_at)).to all(be_present)

      PushJob.perform_now("driver", lines.map(&:id))
      expect(fake_push.sent.size).to eq(2)
    end

    it "pushes the lines Sync writes for a trip given to the driver (bulk insert), with the run" do
      register(driver_token("91234567"))
      sign_in_as(create(:user, :admin, company:))
      vehicle = within_tenant(company) { create(:vehicle, plate: "PD3318K").tap { it.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1)) } }
      perform_enqueued_jobs do
        post api_v1_trips_path, params: { trip: {
          kind: "ad_hoc", client_id: within_tenant(company) { create(:client).id }, title: "Google Shuttle", starts_on: "2026-11-03", days: [ 1, 2, 3, 4, 5 ],
          end_mode: "never", start_time: "08:00", end_time: "09:00", price: 100, trip_value: 1,
          stops_attributes: [ { position: 0, name: "Jurong East", use: "pu" }, { position: 1, name: "MBC", use: "do" } ],
          vehicle_requirements_attributes: [ { vehicle_type_id: create(:vehicle_type).id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: vehicle.id } ]
        } }, as: :json
      end
      expect(response).to have_http_status(:created)
      runs = within_tenant(company) { TripOccurrence.where(trip_id: json.dig(:data, :id)).where(date: [ Date.new(2026, 11, 3), Date.new(2026, 11, 4) ]).order(:date).to_a }
      expect(fake_push.sent.map { [ it[:body], it[:data].values_at(:kind, :run_id, :run_date) ] }).to contain_exactly(
        [ "Google Shuttle on today, 08:00. Open it to see the stops.", [ "run_assigned", runs[0].id.to_s, "2026-11-03" ] ],
        [ "Google Shuttle on tomorrow, 08:00. Open it to see the stops.", [ "run_assigned", runs[1].id.to_s, "2026-11-04" ] ]
      )
    end

    it "drops a token Firebase no longer knows and keeps the line unpushed; no phone, nothing sent" do
      register(driver_token("91234567"))
      fake_push.gone << "fcm-kumar"
      perform_enqueued_jobs { bell_line(kumar) }
      expect(DriverDevice.count).to eq(0)
      perform_enqueued_jobs { bell_line(kumar) }
      expect(fake_push.sent).to be_empty
      expect(DriverNotification.unscoped.pluck(:pushed_at)).to all(be_nil)
    end

    it "queues nothing while paused (the seed)" do
      register(driver_token("91234567"))
      Push.pausing { bell_line(kumar) }
      expect(enqueued_jobs.select { it[:job] == PushJob }).to be_empty
    end
  end
end
