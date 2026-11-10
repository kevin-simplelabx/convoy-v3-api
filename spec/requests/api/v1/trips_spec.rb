require "rails_helper"

RSpec.describe "Trips" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[vehicles]) }
  let!(:setup) do
    within_tenant(company) do
      { client: create(:client, name: "Google"), type: create(:vehicle_type, seats: 23), bus: create(:vehicle, plate: "PC8841T", seats: 23) }
    end
  end

  let(:base) do
    {
      kind: "ad_hoc", client_id: setup[:client].id, starts_on: "2026-11-02", start_time: "08:00", end_time: "09:15", pax: 20,
      stops_attributes: [
        { position: 0, name: "Mapletree Business City", use: "pu", lat: 1.2747, lng: 103.7993 },
        { position: 1, name: "Sentosa", use: "do", lat: 1.2494, lng: 103.8303, driver_note: "Drop at the coach bay" }
      ],
      vehicle_requirements_attributes: [ { vehicle_type_id: setup[:type].id, count: 1 } ],
      vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: setup[:bus].id } ],
      standby_attributes: { location: "Pasir Panjang carpark", minutes: 15 }
    }
  end

  before { sign_in_as(user) }

  it "creates a trip with its stops, buses and standby" do
    post api_v1_trips_path, params: { trip: base }, as: :json
    expect(response).to have_http_status(:created)
    trip = json[:data]
    expect(trip).to include(title: "Google", trip_id: "TID100001", start_time: "08:00", route_text: "Mapletree Business City to Sentosa")
    expect(trip[:stops].pluck(:name)).to eq([ "Mapletree Business City", "Sentosa" ])
    expect(trip[:vehicle_slots].first).to include(plate: "PC8841T")
    expect(trip[:standby]).to include(location: "Pasir Panjang carpark", report_time: "07:45")
  end

  describe "GET /trips/next_number" do
    it "starts at TID100001 and creates no sequence row" do
      get next_number_api_v1_trips_path
      expect(json[:data]).to eq(trip_id: "TID100001")
      expect(within_tenant(company) { CompanySequence.where(name: "trip_no").count }).to eq(0)
    end

    it "does not reserve a number: previewing twice and saving gives the previewed number" do
      get next_number_api_v1_trips_path
      get next_number_api_v1_trips_path
      expect(json[:data][:trip_id]).to eq("TID100001")
      post api_v1_trips_path, params: { trip: base }, as: :json
      expect(json.dig(:data, :trip_id)).to eq("TID100001")
      get next_number_api_v1_trips_path
      expect(json[:data][:trip_id]).to eq("TID100002")
    end

    it "skips the whole block of a recurring trip" do
      post api_v1_trips_path, params: { trip: base.merge(days: [ 1, 2, 3 ], end_mode: "date", ends_on: "2026-11-08") }, as: :json
      get next_number_api_v1_trips_path
      expect(json[:data][:trip_id]).to eq("TID100008")
    end
  end

  it "creates the return of a two-way trip and links them" do
    back = {
      start_time: "17:00", end_time: "18:00",
      stops_attributes: [ { position: 0, name: "Sentosa", use: "pu", lat: 1.2495, lng: 103.8302 },
                          { position: 1, name: "Mapletree Business City", use: "do", lat: 1.2747, lng: 103.7993 } ]
    }
    post api_v1_trips_path, params: { trip: base, return_trip: back }, as: :json
    out = json[:data]
    ret = json.dig(:meta, :return_trip)
    expect(ret).to include(title: "Google (Return)", is_return: true, pair_id: out[:id], start_time: "17:00")
    expect(ret[:vehicle_slots].first).to include(plate: "PC8841T")
    get api_v1_trip_path(out[:id])
    expect(json[:data]).to include(pair_id: ret[:id], return_billing: "two_way")
  end

  it "refuses a return that starts before the trip ends" do
    post api_v1_trips_path, params: { trip: base, return_trip: { start_time: "09:00", end_time: "10:00", stops_attributes: base[:stops_attributes] } }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("The return starts before the outbound trip ends")
  end

  it "reorders stops in one save and uploads stop photos" do
    post api_v1_trips_path, params: { trip: base }, as: :json
    id = json.dig(:data, :id)
    a, b = json.dig(:data, :stops).pluck(:id)

    patch api_v1_trip_path(id), params: { trip: { stops_attributes: [ { id: a, position: 1, use: "do" }, { id: b, position: 0, use: "pu" } ] } }, as: :json
    expect(json.dig(:data, :stops).pluck(:name)).to eq([ "Sentosa", "Mapletree Business City" ])

    photo = fixture_file_upload("photo.png", "image/png")
    patch api_v1_trip_path(id), params: { trip: { stops_attributes: { "0" => { id: b, photos_attributes: { "0" => { photo: } } } } } }
    expect(json.dig(:data, :stops, 0, :photos, 0, :thumb_url)).to start_with("/api/v1/downloads/")
  end

  it "rejects a stale edit" do
    post api_v1_trips_path, params: { trip: base }, as: :json
    id = json.dig(:data, :id)
    patch api_v1_trip_path(id), params: { trip: { pax: 10, lock_version: 0 } }, as: :json
    patch api_v1_trip_path(id), params: { trip: { pax: 12, lock_version: 0 } }, as: :json
    expect(response).to have_http_status(:conflict)
  end

  it "lists trips by Trip ID, client and date range" do
    post api_v1_trips_path, params: { trip: base }, as: :json
    post api_v1_trips_path, params: { trip: base.merge(days: [ 1, 3, 5 ], end_mode: "never") }, as: :json

    get api_v1_trips_path, params: { q: "TID100005" }
    expect(json[:data].size).to eq(1)
    expect(json[:data].first).to include(repeat_text: "Mon Wed Fri")

    get api_v1_trips_path, params: { from: "2027-03-01", to: "2027-03-31" }
    expect(json[:data].size).to eq(1)

    get api_v1_trips_path, params: { vehicle_id: setup[:bus].id }
    expect(json[:data].size).to eq(2)
  end

  it "soft deletes and keeps the calendar from being deleted while used" do
    cal = within_tenant(company) { create(:calendar) }
    post api_v1_trips_path, params: { trip: base.merge(days: [ 1 ], end_mode: "never", calendar_id: cal.id) }, as: :json
    trip_id = json.dig(:data, :id)
    delete api_v1_calendar_path(cal)
    expect(response).to have_http_status(:unprocessable_content)

    delete api_v1_trip_path(trip_id)
    expect(response).to have_http_status(:no_content)
    delete api_v1_calendar_path(cal)
    expect(response).to have_http_status(:no_content)
  end
end
