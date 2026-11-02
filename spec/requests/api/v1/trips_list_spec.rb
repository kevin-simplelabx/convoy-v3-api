require "rails_helper"

RSpec.describe "Trips page (run list)" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:) }
  let!(:d) do
    within_tenant(company) do
      op = create(:operator, name: "Hup Seng")
      own = create(:vehicle, plate: "PD1A", seats: 13)
      managed = create(:vehicle, plate: "PM2B", seats: 45, operator: op)
      own.driver_schedules.create!(driver: create(:driver, name: "Eric"), starts_on: Date.new(2026, 10, 1))
      { op:, own:, managed:, client: create(:client, name: "Google"), type: create(:vehicle_type, name: "13-seater") }
    end
  end

  def trip(title, start_time, end_time, vehicle_id: nil, starts_on: "2026-11-02")
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", title:, client_id: d[:client].id, starts_on:, start_time:, end_time:,
      stops_attributes: [ { position: 0, name: "Changi", use: "pu" }, { position: 1, name: "Marina", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: d[:type].id, count: 1 } ],
      vehicle_slots_attributes: vehicle_id ? [ { slot_no: 1, vehicle_id: } ] : []
    } }, as: :json
    expect(response).to have_http_status(:created)
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 30)
    sign_in_as(user)
    trip("Done run", "07:00", "08:00", vehicle_id: d[:own].id)
    trip("Live run", "09:00", "10:00", vehicle_id: d[:managed].id)
    trip("Later run", "14:00", "15:00", vehicle_id: d[:own].id)
    trip("Open run", "16:00", "17:00")
    trip("Tomorrow run", "08:00", "09:00", vehicle_id: d[:own].id, starts_on: "2026-11-03")
  end

  it "lists runs with chip counts and the filter menus" do
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03" }
    expect(json[:data].pluck(:title)).to eq([ "Done run", "Live run", "Later run", "Open run", "Tomorrow run" ])
    expect(json[:meta][:counts]).to eq(all: 5, unassigned: 1, assigned: 2, live: 1, completed: 1, cancelled: 0)
    expect(json[:meta][:kinds]).to eq(%w[ad_hoc])
    expect(json[:meta][:operators]).to eq([ { id: d[:op].id, name: "Hup Seng", kind: "managed" } ])

    open = json[:data].find { |r| r[:title] == "Open run" }
    expect(open).to include(status_group: "unassigned", plate: nil, required_vehicle_type: "13-seater", customer: "Google", route_text: "Changi to Marina")
    live = json[:data].find { |r| r[:title] == "Live run" }
    expect(live).to include(status_group: "live", vehicle_seats: 45, operator: { id: d[:op].id, name: "Hup Seng", kind: "managed" })
  end

  it "filters by status, operator, search and sorts newest first" do
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", status_group: "assigned", sort: "date_desc" }
    expect(json[:data].pluck(:title)).to eq([ "Tomorrow run", "Later run" ])
    expect(json[:meta][:counts][:all]).to eq(5)

    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", operator: "own" }
    expect(json[:data].pluck(:plate).uniq).to eq(%w[PD1A])
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", operator: "none" }
    expect(json[:data].pluck(:title)).to eq([ "Open run" ])
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", operator: d[:op].id }
    expect(json[:data].pluck(:title)).to eq([ "Live run" ])

    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", q: "eric" }
    expect(json[:meta][:counts][:all]).to eq(3)
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", q: "marina" }
    expect(json[:meta][:count]).to eq(5)
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-03", q: "hup" }
    expect(json[:data].pluck(:title)).to eq([ "Live run" ])
  end

  it "counts a cancelled run under Cancelled" do
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-02", q: "Later" }
    run = json[:data].first
    patch cancel_api_v1_occurrence_path(run[:id]), params: { lock_version: run[:lock_version] }, as: :json
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2026-11-02", status_group: "cancelled" }
    expect(json[:data].pluck(:title)).to eq([ "Later run" ])
  end

  it "refuses more than 6 months or reversed dates" do
    get list_api_v1_occurrences_path, params: { from: "2026-11-02", to: "2027-06-01" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Trips show up to 6 months at a time")
    get list_api_v1_occurrences_path, params: { from: "2026-11-03", to: "2026-11-02" }
    expect(response).to have_http_status(:unprocessable_content)
    get list_api_v1_occurrences_path, params: { from: "2026-11-02" }
    expect(response).to have_http_status(:bad_request)
  end
end
