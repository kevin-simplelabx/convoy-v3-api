require "rails_helper"

RSpec.describe "Maintenance, notices, tracking links and stop photos" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar Rajan")
      bus = create(:vehicle, plate: "PD3318K", seats: 13)
      bus.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      create(:vehicle_type, seats: 13, tyre_layout: "1-1")
      { bus:, kumar:, client: create(:client, name: "Google"), type: VehicleType.first }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    sign_in_as(create(:user, company:))
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", client_id: f[:client].id, starts_on: "2026-10-26", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00",
      stops_attributes: [ { position: 0, name: "Jurong East", use: "pu", lat: 1.333, lng: 103.742 }, { position: 1, name: "MBC", use: "do", lat: 1.274, lng: 103.799 } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:bus].id } ]
    } }, as: :json
    @trip = json[:data]
  end

  def run_on(date)
    get api_v1_occurrences_path, params: { trip_id: @trip[:id], date: }
    json[:data].first
  end

  describe "maintenance" do
    it "plans a visit with the day's driver and a new workshop, shows it on the grid and warns on a drop" do
      get new_api_v1_maintenance_visit_path, params: { vehicle_id: f[:bus].id, date: "2026-11-04", start_time: "08:30" }
      blank = json[:data]
      expect(blank).to include(driver_id: f[:kumar].id, end_time: "10:30", tyre_positions: [ "Front Left", "Front Right", "Rear Left", "Rear Right", "Spare" ])

      post api_v1_maintenance_visits_path, params: { maintenance_visit: blank.slice(:vehicle_id, :driver_id, :date, :start_time, :end_time, :kind).merge(work_to_do: "30,000 km service"),
                                                     workshop_name: "Ah Huat Motor", workshop_address: "Kaki Bukit" }, as: :json
      expect(response).to have_http_status(:created)
      visit = json[:data]
      expect(visit).to include(workshop_name: "Ah Huat Motor", status: "scheduled", tab: "upcoming")
      expect(visit[:driver_notified_at]).to be_present

      get api_v1_scheduler_path, params: { from: "2026-11-04" }
      expect(json.dig(:data, :maintenance).pluck(:plate)).to eq(%w[PD3318K])

      get move_preview_api_v1_occurrence_path(run_on("2026-11-04")[:id]), params: { vehicle_id: f[:bus].id }
      expect(json.dig(:data, :warnings)).to include("PD3318K is at Ah Huat Motor 08:30–10:30")

      get api_v1_workshops_path
      delete api_v1_workshop_path(json[:data].first[:id])
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "records the work from a read invoice, with GST and tyre positions" do
      post api_v1_maintenance_visits_path, params: { maintenance_visit: { vehicle_id: f[:bus].id, date: "2026-10-30", start_time: "09:00", end_time: "11:00" },
                                                     workshop_name: "Ah Huat Motor" }, as: :json
      id = json.dig(:data, :id)

      patch api_v1_maintenance_visit_path(id), params: { maintenance_visit: { status: "completed" } }, as: :json
      expect(json.dig(:error, :message)).to include("Odometer must be entered", "Add the line items from the invoice")

      fake_claude.reply = {
        is_invoice: true, workshop: "Ah Huat Motor", address: "Kaki Bukit Ave 1", date: "2026-10-30", plate: "PD3318X", odometer: "84,210", gst: true,
        lines: [ { type: "labour", description: "Service labour", part_number: "", brand: "", model: "", tyre_position: "", quantity: "1", unit_price: "120" },
                 { type: "tyre", description: "", part_number: "", brand: "Michelin", model: "Agilis", tyre_position: "Front Left", quantity: "1", unit_price: "180" } ]
      }
      perform_enqueued_jobs { post api_v1_document_reads_path, params: { kind: "maintenance_invoice", file: fixture_file_upload("sample.pdf", "application/pdf") } }
      read_id = json.dig(:data, :id)

      patch api_v1_maintenance_visit_path(id), params: { maintenance_visit: { status: "completed" }, document_read_id: read_id }, as: :json
      expect(json.dig(:meta, :filled)).to eq(%w[address odometer lines])
      expect(json.dig(:meta, :warnings)).to eq([ "The invoice is for PD3318X, not PD3318K" ])
      expect(json[:data]).to include(status: "completed", odometer: 84_210, subtotal: "300.0", gst: "27.0", total: "327.0", tab: "completed")
      expect(json.dig(:data, :invoices).size).to eq(1)

      line = json.dig(:data, :lines).last[:id]
      patch api_v1_maintenance_visit_path(id), params: { maintenance_visit: { lines_attributes: [ { id: line, tyre_position: "Rear Left Outer" } ] } }, as: :json
      expect(json.dig(:error, :message)).to eq("Pick the position of each tyre")
    end
  end

  describe "notices" do
    it "sends a banner now for a period, shows it in the drawer, then ends it" do
      get api_v1_notice_templates_path
      expect(json[:data]).to eq([]) # templates are seeded per company

      post api_v1_notices_path, params: { notice: { trip_id: @trip[:id], to_riders: true, banner: true, push: true, message: "Running {min} minutes late" },
                                          period_minutes: 15 }, as: :json
      expect(json.dig(:error, :message)).to eq("Message still has {min} to fill in")

      post api_v1_notices_path, params: { notice: { trip_id: @trip[:id], whatsapp: true, banner: true, message: "Hi" } }, as: :json
      expect(json.dig(:error, :message)).to eq("WhatsApp is not available yet")

      post api_v1_notices_path, params: { notice: { trip_id: @trip[:id], to_riders: true, banner: true, push: true, message: "Running 10 minutes late" },
                                          period_minutes: 15, run_keys: [ "all" ] }, as: :json
      notice = json[:data]
      expect(notice).to include(state: "active", run_keys: [ "all" ])
      expect(notice[:sent].pluck(:channel)).to eq(%w[push])
      expect(Time.zone.parse(notice[:ends_at]) - Time.zone.parse(notice[:starts_at])).to eq(15.minutes)

      get api_v1_occurrence_path(run_on("2026-11-02")[:id])
      expect(json.dig(:data, :notice, :message)).to eq("Running 10 minutes late")
      expect(json.dig(:data, :notice, :by)).to eq(ActsAsTenant.with_tenant(company) { Notice.find(notice[:id]).created_by.name })

      patch api_v1_notice_path(notice[:id]), params: { notice: { message: "x" } }, as: :json
      expect(json.dig(:error, :message)).to start_with("An active or ended notice can't be edited")

      patch end_now_api_v1_notice_path(notice[:id]), as: :json
      expect(json.dig(:data, :state)).to eq("ended")
      post duplicate_api_v1_notice_path(notice[:id]), as: :json
      expect(json.dig(:data, :state)).to eq("active")
      get api_v1_notices_path, params: { state: "ended" }
      expect(json[:data].size).to eq(1)
    end
  end

  describe "tracking links" do
    it "shares a public link for a run that closes 24 hours after it ends" do
      occ = run_on("2026-11-03")
      post tracking_link_api_v1_occurrence_path(occ[:id]), as: :json
      token = json.dig(:data, :token)
      expect(json.dig(:data, :expires_at)).to eq(Time.zone.local(2026, 11, 4, 9, 0).as_json)

      delete api_v1_session_path
      get api_v1_public_tracking_path(token)
      expect(response).to have_http_status(:ok)
      expect(json[:data]).to include(state: "upcoming", trip_label: occ[:trip_label], driver: "Kumar", powered_by: "CONVOY")
      expect(json.dig(:data, :stops).map { |s| [ s[:name], s[:time] ] }).to eq([ %w[Jurong\ East 08:00], %w[MBC 09:00] ])

      travel_to Time.zone.local(2026, 11, 4, 9, 1)
      get api_v1_public_tracking_path(token)
      expect(response).to have_http_status(:gone)
    end

    it "refreshes the link when shared again" do
      occ = run_on("2026-11-03")
      post tracking_link_api_v1_occurrence_path(occ[:id]), as: :json
      first = json.dig(:data, :token)
      post tracking_link_api_v1_occurrence_path(occ[:id]), as: :json
      expect(json.dig(:data, :token)).not_to eq(first)
      get api_v1_public_tracking_path(first)
      expect(response).to have_http_status(:not_found)
    end
  end

  it "adds stop photos from the drawer, up to three" do
    stop = @trip[:stops].first[:id]
    3.times { post api_v1_trip_stop_photos_path(@trip[:id], stop), params: { photo: fixture_file_upload("photo.png", "image/png") } }
    expect(json.dig(:data, :thumb_url)).to start_with("/api/v1/downloads/")
    post api_v1_trip_stop_photos_path(@trip[:id], stop), params: { photo: fixture_file_upload("photo.png", "image/png") }
    expect(json.dig(:error, :message)).to eq("Up to 3 photos per stop")
  end
end
