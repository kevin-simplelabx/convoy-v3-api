require "rails_helper"

RSpec.describe "Scheduler and runs" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:) }
  let!(:d) do
    within_tenant(company) do
      bus = create(:vehicle, plate: "PD1A", seats: 13)
      driver = create(:driver, name: "Eric")
      bus.driver_schedules.create!(driver:, starts_on: Date.new(2026, 10, 1))
      { bus:, driver:, client: create(:client, name: "Google"), type: create(:vehicle_type) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    sign_in_as(user)
    trip = {
      kind: "ad_hoc", client_id: d[:client].id, starts_on: "2026-10-26", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00", stops_attributes: [ { position: 0, name: "A", use: "pu" }, { position: 1, name: "B", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: d[:type].id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: d[:bus].id } ]
    }
    post api_v1_trips_path, params: { trip: }, as: :json
    post api_v1_trips_path, params: { trip: trip.merge(days: [], end_mode: nil, starts_on: "2026-11-03", vehicle_slots_attributes: []) }, as: :json
  end

  it "gives the grid for a day: vehicles, runs and unassigned runs" do
    get api_v1_scheduler_path, params: { from: "2026-11-03" }
    expect(json.dig(:data, :vehicles).pluck(:plate)).to eq(%w[PD1A])
    expect(json.dig(:data, :occurrences).size).to eq(1)
    expect(json.dig(:data, :occurrences, 0)).to include(start_time: "08:00", plate: "PD1A", grid_status: "ok")
    expect(json.dig(:data, :occurrences, 0, :driver)).to include(kind: "own", name: "Eric", photo: nil)
    expect(json.dig(:data, :occurrences, 0)).to include(client_name: "Google")
    expect(json.dig(:data, :occurrences, 0, :route_stops)).to eq([ { name: "A", address: nil, use: "pu", time: "08:00" }, { name: "B", address: nil, use: "do", time: "09:00" } ])
    expect(json.dig(:data, :vehicles, 0, :driver)).to include(kind: "own", name: "Eric", photo: nil)
    expect(json.dig(:data, :unassigned).size).to eq(1)
    expect(json[:meta]).to include(unassigned_before: nil, unassigned_after: nil)
  end

  it "sends the driver's photo thumbnail on the grid rows and runs" do
    within_tenant(company) { d[:driver].update!(photo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/photo.png"), "image/png")) }
    get api_v1_scheduler_path, params: { from: "2026-11-03" }
    expect(json.dig(:data, :vehicles, 0, :driver, :photo)).to start_with("/api/v1/downloads/")
    expect(json.dig(:data, :occurrences, 0, :driver, :photo)).to start_with("/api/v1/downloads/")
  end

  it "has no runs past the horizon (the daily job adds them as it moves)" do
    get api_v1_scheduler_path, params: { from: (Occurrences::Sync.horizon + 1).iso8601 }
    expect(json.dig(:data, :occurrences)).to eq([])
    expect(json[:meta][:horizon]).to eq(Occurrences::Sync.horizon.iso8601)
  end

  it "lists a driver's runs for today and tomorrow" do
    get api_v1_occurrences_path, params: { driver_id: d[:driver].id, date: "2026-11-02" }
    expect(json[:data].pluck(:date)).to eq(%w[2026-11-02])
    get api_v1_occurrences_path, params: { driver_id: d[:driver].id, from: "2026-11-02", to: "2026-11-06" }
    expect(json[:meta][:count]).to eq(5)
  end

  describe "drawer actions" do
    let(:run_id) do
      get api_v1_occurrences_path, params: { date: "2026-11-04", vehicle_id: d[:bus].id }
      json.dig(:data, 0, :id)
    end

    it "cancels and restores, refusing a stale change" do
      patch cancel_api_v1_occurrence_path(run_id), params: { lock_version: 0 }, as: :json
      expect(json.dig(:data, :grid_status)).to eq("cancel")
      patch restore_api_v1_occurrence_path(run_id), params: { lock_version: 0 }, as: :json
      expect(response).to have_http_status(:conflict)
      patch restore_api_v1_occurrence_path(run_id), as: :json
      expect(json.dig(:data, :status)).to eq("scheduled")
      expect(json.dig(:data, :changes).size).to eq(2)
    end

    it "moves one run, then every run from here, then back" do
      patch time_api_v1_occurrence_path(run_id), params: { scope: "today", start_time: "08:20" }, as: :json
      expect(json[:data]).to include(start_time: "08:20", end_time: "09:20", shift_minutes: 20)

      patch time_api_v1_occurrence_path(run_id), params: { scope: "reset" }, as: :json
      expect(json[:data]).to include(start_time: "08:00", shift_minutes: 0)

      patch time_api_v1_occurrence_path(run_id), params: { scope: "from_here", start_time: "07:45" }, as: :json
      get api_v1_occurrences_path, params: { vehicle_id: d[:bus].id, from: "2026-11-03", to: "2026-11-05" }
      expect(json[:data].pluck(:start_time)).to eq(%w[08:00 07:45 07:45])
    end

    it "force ends a run on the road, once" do
      patch end_api_v1_occurrence_path(run_id), as: :json
      expect(json.dig(:error, :message)).to eq("This run has not started")

      travel_to Time.zone.local(2026, 11, 4, 8, 30)
      patch end_api_v1_occurrence_path(run_id), as: :json
      expect(json[:data]).to include(status: "completed", grid_status: "done", ended_by: user.name, end_time: "09:00")
      expect(Time.zone.parse(json.dig(:data, :ended_at))).to eq(Time.current)

      patch end_api_v1_occurrence_path(run_id), as: :json
      expect(json.dig(:error, :message)).to eq("This run has already ended")

      travel_to Time.zone.local(2026, 11, 3, 8, 30) # the one-off trip of that day has no bus
      get api_v1_occurrences_path, params: { date: "2026-11-03", unassigned: 1 }
      patch end_api_v1_occurrence_path(json.dig(:data, 0, :id)), as: :json
      expect(json.dig(:error, :message)).to eq("This run has no bus")
    end

    it "raises an issue only on a run that is done" do
      post issue_api_v1_occurrence_path(run_id), params: { reason: "Late" }, as: :json
      expect(response).to have_http_status(:unprocessable_content)

      get api_v1_occurrences_path, params: { date: "2026-10-30", vehicle_id: d[:bus].id }
      done = json.dig(:data, 0, :id)
      post issue_api_v1_occurrence_path(done), params: { reason: "Bus came 20 minutes late" }, as: :json
      expect(json.dig(:data, :issue_reason)).to eq("Bus came 20 minutes late")
      delete issue_api_v1_occurrence_path(done), as: :json
      expect(json.dig(:data, :issue_reason)).to be_nil
    end
  end

  it "removes future runs when the trip is deleted and keeps past ones" do
    get api_v1_occurrences_path, params: { vehicle_id: d[:bus].id }
    trip_id = json.dig(:data, 0, :trip_id)
    delete api_v1_trip_path(trip_id)
    get api_v1_occurrences_path, params: { trip_id: }
    expect(json[:data].pluck(:date).max).to eq("2026-10-30")
  end
end
