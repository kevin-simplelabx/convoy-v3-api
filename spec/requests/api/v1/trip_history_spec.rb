require "rails_helper"

RSpec.describe "Trip History" do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company:) }
  let!(:f) do
    within_tenant(company) do
      bus = create(:vehicle, plate: "PD1A", seats: 13, make: "Toyota", model: "Hiace")
      bus.driver_schedules.create!(driver: create(:driver, name: "Eric Tan"), starts_on: Date.new(2026, 10, 1))
      create(:public_holiday, date: "2026-10-28", name: "Deepavali")
      { bus:, client: create(:client, name: "Google"), other: create(:client, name: "DBS"), type: create(:vehicle_type) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 12, 0) # Monday
    sign_in_as(user)
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", title: "Office Shuttle", client_id: f[:client].id, starts_on: "2026-10-26", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00", requestor_name: "Alex", requestor_email: "alex@google.com",
      stops_attributes: [ { position: 0, name: "Jurong East", use: "pu" }, { position: 1, name: "MBC", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:bus].id } ]
    } }, as: :json
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", title: "Airport Drop", client_id: f[:other].id, starts_on: "2026-10-30", start_time: "15:00", end_time: "16:00",
      stops_attributes: [ { position: 0, name: "Raffles", use: "pu" }, { position: 1, name: "Changi", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ]
    } }, as: :json
    within_tenant(company) do
      runs = TripOccurrence.joins(:trip).where(trips: { title: "Office Shuttle" })
      Occurrences::Edit.new(runs.find_by(date: "2026-10-29"), user).cancel!(by_client: true)
      Occurrences::Edit.new(runs.find_by(date: "2026-10-30"), user).cancel!
      Occurrences::Complete.call
    end
  end

  def history(**params)
    get api_v1_trip_history_path, params: { from: "2026-10-26", to: "2026-11-02" }.merge(params)
    expect(response).to have_http_status(:ok), response.body
    json
  end

  it "lists what ran, was cancelled or skipped up to today, with filter counts" do
    data = history
    expect(data[:data].map { |r| [ r[:date], r[:title], r[:outcome] ] }).to eq([
      [ "2026-11-02", "Office Shuttle", "completed" ],
      [ "2026-10-30", "Airport Drop", "completed" ],
      [ "2026-10-30", "Office Shuttle", "cancelled_by_us" ],
      [ "2026-10-29", "Office Shuttle", "cancelled_by_client" ],
      [ "2026-10-28", "Office Shuttle", "skipped" ],
      [ "2026-10-27", "Office Shuttle", "completed" ],
      [ "2026-10-26", "Office Shuttle", "completed" ]
    ])
    skipped = data[:data].find { |r| r[:outcome] == "skipped" }
    expect(skipped).to include(outcome_label: "Skipped by Calendar", skip_reason: "Public holiday: Deepavali", pax: nil, on_time: "na")
    expect(data[:data].first).to include(driver_name: "Eric Tan", operator: "Own fleet", vehicle: hash_including(plate: "PD1A", make: "Toyota"))
    expect(data[:meta]).to include(from: "2026-10-26", to: "2026-11-02", on_time_minutes: 5)
    expect(data[:meta][:facets][:outcome]).to eq([
      { value: "cancelled_by_client", label: "Cancelled by Client", count: 1 }, { value: "cancelled_by_us", label: "Cancelled by Us", count: 1 },
      { value: "completed", label: "Completed", count: 4 }, { value: "skipped", label: "Skipped by Calendar", count: 1 }
    ])
    expect(data[:meta][:facets][:client_id]).to eq([ { value: f[:other].id.to_s, label: "DBS", count: 1 }, { value: f[:client].id.to_s, label: "Google", count: 6 } ])

    # A filter narrows the others' counts, not its own.
    data = history(outcome: %w[completed], client_id: [ f[:client].id ])
    expect(data[:meta][:count]).to eq(3)
    expect(data[:meta][:facets][:outcome].find { |x| x[:value] == "skipped" }[:count]).to eq(1)
    expect(data[:meta][:facets][:client_id].find { |x| x[:label] == "DBS" }[:count]).to eq(1)

    expect(history(operator: %w[none])[:data].pluck(:title)).to eq([ "Airport Drop" ])
    expect(history(q: "eric", sort: "old")[:data].pluck(:date).first).to eq("2026-10-26")
    expect(history(sort: "client")[:data].first[:title]).to eq("Airport Drop")
    expect(history(needs_look: true)[:meta][:count]).to eq(0)

    get api_v1_trip_history_path, params: { from: "2025-01-01", to: "2026-11-02" }
    expect(json.dig(:error, :message)).to eq("Trip History shows up to a year at a time")
  end

  it "shows a run's record and keeps notes" do
    id = history[:data].find { |r| r[:date] == "2026-10-27" }[:id]
    within_tenant(company) do
      occ = TripOccurrence.find(id)
      report = OccurrenceDriverReport.create!(occurrence: occ, driver_name: "Eric Tan", note: "Smooth run", submitted_at: occ.ends_at + 5.minutes)
      report.photos.create!(image: Rack::Test::UploadedFile.new(file_fixture("photo.png"), "image/png"), caption: "Drop-off")
    end

    get api_v1_trip_history_run_path(id)
    rec = json[:data]
    expect(rec).to include(outcome: "completed", outcome_label: "Completed", title: "Office Shuttle", start_time: "08:00", not_run: nil, needs_look: false)
    expect(rec[:vehicle]).to include(plate: "PD1A", ownership: "own")
    expect(rec[:crew][:driver]).to include(name: "Eric Tan")
    expect(rec[:stops].map { |s| [ s[:name], s[:planned_time] ] }).to eq([ [ "Jurong East", "08:00" ], [ "MBC", nil ] ])
    expect(rec[:trip_info]).to include(recurrence: "Mon to Fri", kind_name: "Ad Hoc / Charter")
    expect(rec[:point_of_contact][:requestor]).to include(name: "Alex", email: "alex@google.com")
    expect(rec[:driver_report]).to include(driver_name: "Eric Tan", note: "Smooth run")
    expect(rec[:driver_report][:photos].first).to include(caption: "Drop-off", name: "photo.png")
    # Newest first; the trip was entered today, after these (backdated) runs.
    expect(rec[:log].pluck(:text)).to eq([ "Trip created", "Driver's report sent", "Run completed", "Planned start" ])

    post api_v1_trip_history_notes_path(id), params: { body: "Driver reminded about the 60 km/h limit" }, as: :json
    expect(response).to have_http_status(:created)
    expect(json.dig(:data, :notes, 0)).to include(body: "Driver reminded about the 60 km/h limit", by: user.name)
    expect(json.dig(:data, :needs_look)).to be(true)
    expect(history(needs_look: true)[:data].pluck(:id)).to eq([ id ])

    skipped = history[:data].find { |r| r[:outcome] == "skipped" }[:id]
    get api_v1_trip_history_run_path(skipped)
    expect(json.dig(:data, :not_run)).to eq(kind: "skipped", reason: "Public holiday: Deepavali")
    cancelled = history[:data].find { |r| r[:outcome] == "cancelled_by_client" }[:id]
    get api_v1_trip_history_run_path(cancelled)
    expect(json.dig(:data, :not_run)).to include(kind: "cancelled", by_client: true, by: user.name)
  end

  it "corrects a run's record, keeping what was recorded and each change with who and why" do
    id = history[:data].find { |r| r[:date] == "2026-10-27" }[:id]
    other = within_tenant(company) { create(:vehicle, plate: "PD2B", seats: 13) }
    correct = lambda do |body, lock = nil|
      post api_v1_trip_history_correction_path(id), params: { lock_version: lock, correction: body }, as: :json
      json
    end

    expect(correct.({ outcome: "completed", reason: "x" }).dig(:error, :message)).to eq("Nothing has changed")
    expect(correct.({ outcome: "incomplete" }).dig(:error, :message)).to eq("Give the reason for the correction")
    expect(correct.({ stops: [ { position: 0, arrived_at: "08:05", departed_at: "08:01" } ], reason: "x" }).dig(:error, :message))
      .to eq("Stop 1: departure is before arrival")
    expect(correct.({ stops: [ { position: 5, boarded: 1 } ], reason: "x" }).dig(:error, :message)).to eq("Stop 5 isn't on this run")

    rec = correct.({ outcome: "incomplete", vehicle_plate: "pd 2b", driver_name: "Ali Hassan",
                     stops: [ { position: 0, arrived_at: "08:03", departed_at: "08:06", boarded: 9 }, { position: 1, alighted: "" } ],
                     reason: "Driver app lost signal, times from the log sheet" })[:data]
    expect(response).to have_http_status(:ok), response.body
    expect(rec).to include(outcome: "incomplete", corrected: true, needs_look: true, correction_lock_version: 0,
                           was: { outcome_label: "Completed", plate: "PD1A", driver_name: "Eric Tan" })
    expect(rec[:vehicle]).to include(id: other.id, plate: "PD2B")
    expect(rec[:crew][:driver]).to include(name: "Ali Hassan", kind: "corrected")
    expect(rec[:stops][0]).to include(arrived_at: "08:03", departed_at: "08:06", boarded: 9, alighted: nil,
                                      was: { arrived_at: nil, departed_at: nil, boarded: nil })
    expect(rec[:stops][1]).to include(arrived_at: nil, was: {})
    expect(rec[:corrections].first).to include(by: user.name, reason: "Driver app lost signal, times from the log sheet", items: [
      "Outcome: Completed to Incomplete", "Vehicle: PD1A to PD2B", "Driver: Eric Tan to Ali Hassan",
      "Stop 1 arrival: N/A to 08:03", "Stop 1 departure: N/A to 08:06", "Stop 1 boarded: N/A to 9"
    ])
    expect(rec[:log].first).to include(text: "Record corrected: Driver app lost signal, times from the log sheet", by: user.name)

    row = history[:data].find { |r| r[:id] == id }
    expect(row).to include(outcome: "incomplete", corrected: true, pax: 9, driver_name: "Ali Hassan", vehicle: hash_including(plate: "PD2B"))
    data = history(outcome: %w[incomplete])
    expect(data[:data].pluck(:id)).to eq([ id ])
    expect(data[:meta][:facets][:driver].pluck(:value)).to include("Ali Hassan")
    expect(history(needs_look: true)[:data].pluck(:id)).to eq([ id ])
    expect(history(q: "PD2B")[:data].pluck(:id)).to eq([ id ])

    expect(correct.({ outcome: "completed", reason: "y" }, 0)[:data]).to include(outcome: "completed", correction_lock_version: 1)
    correct.({ outcome: "incomplete", reason: "y" }, 0)
    expect(response).to have_http_status(:conflict)

    # Back to the recorded values: the corrections go, the history stays.
    rec = correct.({ vehicle_id: f[:bus].id, driver_name: "eric tan", reason: "Mixed up the buses" })[:data]
    expect(rec).to include(corrected: true, was: {})
    expect(rec[:vehicle]).to include(plate: "PD1A")
    expect(rec[:corrections].size).to eq(3)

    cancelled = history[:data].find { |r| r[:outcome] == "cancelled_by_us" }[:id]
    post api_v1_trip_history_correction_path(cancelled), params: { correction: { outcome: "completed", reason: "x" } }, as: :json
    expect(json.dig(:error, :message)).to eq("Only a run that ran can be corrected")
  end

  it "works out On Time, distance and the driving summary from the GPS pings and stop events" do
    id = history[:data].find { |r| r[:date] == "2026-10-27" }[:id]
    within_tenant(company) do
      occ = TripOccurrence.find(id)
      t0 = occ.starts_at
      # 08:00 → 08:40 from (1.333, 103.742) east to MBC, every 10 s; a burst at 90 km/h for a minute.
      points = (0..240).map do |i|
        speed = i.zero? || i == 240 ? 0 : (i.between?(100, 105) ? 90 : 40)
        { at: t0 + (i * 10).seconds, lat: 1.333, lng: 103.742 + (i * 0.0005), speed_kmh: speed, heading: 90 }
      end
      Telematics::Record.call(occ:, positions: points, odometer_start_km: 48_210, stop_events: [
        { position: 0, arrived_at: t0 + 2.minutes, departed_at: t0 + 4.minutes, boarded: 8 },
        { position: 1, arrived_at: t0 + 40.minutes, departed_at: t0 + 41.minutes, alighted: 8 }
      ])
      expect(occ.reload.max_delay_minutes).to eq(2)
    end

    row = history[:data].find { |r| r[:id] == id }
    expect(row).to include(on_time: "on_time", pax: 8, needs_look: true)
    expect(row[:distance_km].to_f).to be_within(0.5).of(13.4)
    expect(history(on_time: %w[on_time])[:data].pluck(:id)).to eq([ id ])
    expect(history[:meta]).to include(speed_limit_kmh: 80)

    get api_v1_trip_history_run_path(id)
    rec = json[:data]
    expect(rec).to include(on_time: "on_time", has_track: true)
    expect(rec[:stops].map { |s| s.slice(:arrived_at, :departed_at, :boarded, :served, :delay_minutes, :late, :on_board) }).to eq([
      { arrived_at: "08:02", departed_at: "08:04", boarded: 8, served: true, delay_minutes: 2, late: false, on_board: 8 },
      { arrived_at: "08:40", departed_at: "08:41", boarded: nil, served: true, delay_minutes: nil, late: false, on_board: 0 }
    ])
    expect(rec[:stop_summary]).to include(duration_minutes: 40, stops_total: 2, stops_served: 2, late_stops: [], boarded: 8)
    expect(rec[:speed]).to include(max_kmh: "90.0", limit_kmh: 80, overspeed_seconds: 60)
    expect(rec[:driving_summary]).to include(planned_minutes: 60, vs_plan_minutes: -20, odometer_start_km: 48_210, odometer_end_km: 48_223,
                                             harsh_events: 4, ping_count: 241, ping_interval_seconds: 10, fuel_unit: "L", fuel_estimated: true)
    expect(rec[:log].pluck(:text)).to include("PD1A started the trip at Jurong East", "PD1A departed from Jurong East", "PD1A ended the trip at MBC")

    get api_v1_trip_history_track_path(id)
    expect(json.dig(:data, :columns)).to eq(%w[at lat lng speed_kmh heading])
    expect(json.dig(:data, :points).size).to eq(241)
    expect(json.dig(:data, :points, 0)).to eq([ "2026-10-27T08:00:00+08:00", 1.333, 103.742, 0.0, 90 ])

    # A corrected arrival counts for On Time.
    post api_v1_trip_history_correction_path(id), params: { correction: { stops: [ { position: 0, arrived_at: "08:09", departed_at: "08:11" } ], reason: "Log sheet" } }, as: :json
    expect(json[:data]).to include(on_time: "late"), response.body
    expect(json.dig(:data, :stops, 0)).to include(arrived_at: "08:09", late: true, delay_minutes: 9, was: { arrived_at: "08:02", departed_at: "08:04" })
    expect(history(on_time: %w[late])[:data].pluck(:id)).to eq([ id ])
  end

  it "keeps skipped runs off the Scheduler and out of drawer actions" do
    skipped = history[:data].find { |r| r[:outcome] == "skipped" }
    get api_v1_scheduler_path, params: { from: "2026-10-28" }
    expect(json.dig(:data, :occurrences)).to eq([])
    patch cancel_api_v1_occurrence_path(skipped[:id]), as: :json
    expect(json.dig(:error, :message)).to eq("This run does not run that day (Public holiday: Deepavali)")
  end
end
