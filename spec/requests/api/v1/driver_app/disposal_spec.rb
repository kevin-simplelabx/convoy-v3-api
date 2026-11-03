require "rails_helper"

# Convoy Driver app › Disposal: the block starts at the agreed time (or now, when the coordinator asked to start early;
# a late coordinator does not move it), runs tapped on and off, Extend Time signed by the client, overtime in 15-minute
# blocks after 14 free minutes, End with the odometer and who released the bus, Trip History, and the next day's start
# odometer from today's end.
RSpec.describe "Driver app disposal" do
  include ActionDispatch::TestProcess::FixtureFile

  let(:company) { create(:company, name: "SimpleDrive") }
  let(:day) { Date.new(2026, 11, 3) }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      bus = create(:vehicle, plate: "PD3318K")
      bus.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      trip = create(:trip, kind: :disposal, hours: 4, start_time: "12:00", starts_on: day, title: "MBS Team Building Day")
      runs = [ day, day + 1 ].map.with_index do |d, i|
        TripOccurrence.create!(trip:, client: trip.client, date: d, start_time: 720, end_time: 960, starts_at: d.in_time_zone.change(hour: 12),
                               ends_at: d.in_time_zone.change(hour: 16), kind: "disposal", trip_label: "TID00010#{i}", vehicle: bus, driver: kumar, run_key: "d")
      end
      { kumar:, bus:, trip:, runs: }
    end
  end

  def act(token, occ, action, multipart: false, **params)
    params = { client_id: SecureRandom.uuid }.merge(params)
    post public_send(:"#{action}_api_v1_driver_app_run_path", occ.id), params:, headers: as(token), **(multipart ? {} : { as: :json })
    json
  end

  def record = json.dig(:data, :disposal, :record)
  def time(value) = value && Time.zone.parse(value)

  it "runs the block from an early start, logs runs and an extension, bills overtime and ends with the odometer" do
    occ, tomorrow = f[:runs]
    token = driver_token("91234567")
    travel_to Time.zone.local(2026, 11, 3, 11, 30)
    act(token, occ, :start)
    act(token, occ, :arrive, position: 0)
    act(token, occ, :leave, position: 0)
    expect(json.dig(:error, :code)).to eq("disposal_not_started")

    travel_to Time.zone.local(2026, 11, 3, 11, 40)
    act(token, occ, :disposal_start, start: "now")
    expect(json.dig(:error, :details, :start_odometer)).to eq([ "must be a whole number" ])
    act(token, occ, :disposal_start, multipart: true, start: "now", start_odometer: "45,210", start_photo: fixture_file_upload("photo.png", "image/png"))
    expect(response).to have_http_status(:ok), json.inspect
    expect(record).to include(early_start: true, late_minutes: 0, start_odometer: 45_210, start_photo: hash_including(:url))
    expect(time(record[:block_starts_at])).to eq(Time.zone.local(2026, 11, 3, 11, 40))
    expect(record[:clock]).to include(used_minutes: 0, booked_minutes: 240, state: "within")
    expect(json.dig(:data, :points, 0, :record, :departed_at)).to be_present

    travel_to Time.zone.local(2026, 11, 3, 12, 0)
    act(token, occ, :disposal_run_start, from_road: "Bayfront Avenue")
    act(token, occ, :disposal_run_start)
    expect(json.dig(:error, :message)).to eq("A run is on: end it first")
    travel_to Time.zone.local(2026, 11, 3, 12, 25)
    act(token, occ, :disposal_run_end, to_road: "Nicoll Highway", pax: 18)
    expect(record[:runs].map { it.except(:id).merge(started_at: time(it[:started_at]), ended_at: time(it[:ended_at])) }).to eq([
      { started_at: Time.zone.local(2026, 11, 3, 12, 0), ended_at: Time.zone.local(2026, 11, 3, 12, 25), from_road: "Bayfront Avenue",
        to_road: "Nicoll Highway", pax: 18, minutes: 25 }
    ])

    travel_to Time.zone.local(2026, 11, 3, 15, 20)
    expect(act(token, occ, :disposal_extend, minutes: 45, signed_by: "Alex Hwang", operations_told: true).dig(:error, :message)).to eq("Extend in steps of 30 minutes")
    expect(act(token, occ, :disposal_extend, minutes: 30, signed_by: "Alex Hwang").dig(:error, :code)).to eq("tell_operations")
    expect(act(token, occ, :disposal_extend, minutes: 30, operations_told: true).dig(:error, :details, :signed_by)).to eq([ "can't be blank" ])
    act(token, occ, :disposal_extend, multipart: true, minutes: 30, signed_by: "Alex Hwang", operations_told: true, signature: fixture_file_upload("photo.png", "image/png"))
    expect(record).to include(extension_minutes: 30)
    expect(record[:clock]).to include(booked_minutes: 270, used_minutes: 220, state: "within")
    expect(time(record.dig(:clock, :block_ends_at))).to eq(Time.zone.local(2026, 11, 3, 16, 10))
    expect(record.dig(:extensions, 0)).to include(from_minutes: 0, to_minutes: 30, signed_by: "Alex Hwang", signature: hash_including(:url))

    act(token, occ, :complete)
    expect(json.dig(:error, :code)).to eq("disposal_end_needed")

    travel_to Time.zone.local(2026, 11, 3, 16, 20)
    expect(json_clock = act(token, occ, :disposal_run_start, from_road: "Raffles Blvd").dig(:data, :disposal, :record, :clock)).to include(over_minutes: 10, overtime_minutes: 0)
    expect(json_clock[:standing_by_minutes]).to eq(255)

    travel_to Time.zone.local(2026, 11, 3, 16, 40)
    act(token, occ, :disposal_end, end_odometer: 45_100)
    expect(json.dig(:error, :details, :end_odometer)).to eq([ "End odometer must be at least the start reading" ])
    act(token, occ, :disposal_end, multipart: true, end_odometer: 45_242, release_signature: fixture_file_upload("photo.png", "image/png"))
    expect(json.dig(:error, :details, :released_by)).to eq([ "can't be blank" ])
    act(token, occ, :disposal_end, end_odometer: 45_242, released_by: "Alex Hwang")
    expect(json[:data]).to include(status: "ended")
    expect(record).to include(km: 32, end_odometer: 45_242, released_by: "Alex Hwang", ended_at: be_present)
    expect(record[:clock]).to include(used_minutes: 300, over_minutes: 30, overtime_minutes: 30, state: "over")
    expect(record[:runs].last).to include(from_road: "Raffles Blvd", ended_at: be_present)
    within_tenant(company) do
      expect(occ.reload.disposal).to have_attributes(used_minutes: 300, overtime_minutes: 30)
      expect(occ.driver_report.note).to eq("Disposal 5h 0m, 32 km, released by Alex Hwang")
      expect(DriverAppAction.find_by(kind: "disposal_start", occurrence_id: occ.id).payload["start_photo"]).to eq("file:photo.png")
    end

    get api_v1_driver_app_run_path(tomorrow.id), headers: as(token)
    expect(json.dig(:data, :disposal)).to include(hours: 4.0, record: nil, suggested_start_odometer: 45_242)

    travel_to Time.zone.local(2026, 11, 5, 9, 0)
    OccurrenceCompleteJob.perform_now
    sign_in_as(create(:user, :admin, company:))
    get api_v1_trip_history_run_path(occ.id)
    expect(json.dig(:data, :disposal)).to include(km: 32, extension_minutes: 30, released_by: "Alex Hwang")
  end

  it "keeps the agreed start when the coordinator is late" do
    occ = f[:runs].first
    token = driver_token("91234567")
    travel_to Time.zone.local(2026, 11, 3, 12, 10)
    act(token, occ, :start)
    act(token, occ, :arrive, position: 0)
    act(token, occ, :disposal_start, start: "now", start_odometer: 1200)
    expect(record).to include(early_start: false, late_minutes: 10)
    expect(time(record[:block_starts_at])).to eq(Time.zone.local(2026, 11, 3, 12, 0))
    expect(record[:clock]).to include(used_minutes: 10)

    other = within_tenant(company) { TripOccurrence.create!(trip: create(:trip), date: day, start_time: 1000, end_time: 1050, starts_at: day.in_time_zone.change(hour: 16, min: 40), ends_at: day.in_time_zone.change(hour: 17, min: 30), kind: "ad_hoc", trip_label: "TID9", vehicle: f[:bus], driver: f[:kumar], run_key: "z") }
    act(token, other, :disposal_extend, minutes: 30)
    expect(json.dig(:error, :code)).to eq("not_disposal")
  end
end
