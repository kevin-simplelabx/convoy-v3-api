require "rails_helper"

RSpec.describe "Corporate Shuttles" do
  let(:company) { create(:company) }
  let!(:s) do
    within_tenant(company) do
      { client: create(:client, name: "Google"), type: create(:vehicle_type, seats: 23),
        bus1: create(:vehicle, plate: "PC8841T"), bus2: create(:vehicle, plate: "PD4472H") }
    end
  end

  let(:shuttle) do
    {
      kind: "corporate_shuttle", client_id: s[:client].id, starts_on: "2026-11-02", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      vehicles_count: 2, shuttle_return: true, price_by: "run", price_per: "vehicle", price_basis: "trip",
      route_tags: "Campus, Staff", color: "#3267D6", head_count: true, trip_value: 1, trip_value_return: 0.5,
      stops_attributes: [
        { position: 0, name: "Labrador Park MRT", use: "pu", return_name: "Labrador Park MRT Exit B" },
        { position: 1, name: "Alexandra Road", use: "both" },
        { position: 2, name: "Mapletree Business City", use: "do" }
      ],
      vehicle_requirements_attributes: [ { vehicle_type_id: s[:type].id, count: 2 } ],
      runs_attributes: [
        { direction: 1, position: 0, times: %w[07:30 07:40 07:55],
          slots_attributes: [ { slot_no: 1, vehicle_id: s[:bus1].id, group_key: "g1" }, { slot_no: 2, vehicle_id: s[:bus2].id } ] },
        { direction: 1, position: 1, times: [ "08:30", "", "08:50" ],
          slots_attributes: [ { slot_no: 1, vehicle_id: s[:bus1].id, group_key: "g1" }, { slot_no: 2, unassigned: true } ] },
        { direction: 2, position: 0, times: %w[18:00 18:15 18:25], standby_needed: false }
      ],
      price_table: [
        { row: "d1r0", col: "1", amount: 60 }, { row: "d1r0", col: "2", amount: 55 },
        { row: "d1r1", col: "1", amount: 50 }, { row: "d1r1", col: "2", amount: 50 },
        { row: "d2r0", col: "1", amount: 70 }, { row: "d2r0", col: "2", amount: "" }
      ]
    }
  end

  before { sign_in_as(create(:user, company:)) }

  it "saves the timetable, run buses, groups and price table" do
    post api_v1_trips_path, params: { trip: shuttle }, as: :json
    expect(response).to have_http_status(:created)
    t = json[:data]
    expect(t).to include(start_time: "07:30", end_time: "07:55", route_tags: %w[Campus Staff], head_count: true)

    runs = t[:runs]
    expect(runs.pluck(:key, :start_time, :end_time)).to eq([ %w[d1r0 07:30 07:55], %w[d1r1 08:30 08:50], %w[d2r0 18:00 18:25] ])
    expect(runs[1][:times]).to eq([ "08:30", nil, "08:50" ])
    expect(runs[2][:standby_needed]).to be(false)
    expect(runs[0][:slots].pluck(:plate)).to eq(%w[PC8841T PD4472H])
    expect(runs[1][:slots].last).to include(unassigned: true, vehicle_id: nil)
    g = runs[0][:slots].first[:group_key]
    expect(g).to be_present
    expect(runs[1][:slots].first[:group_key]).to eq(g)
    expect(runs[0][:slots].last[:group_key]).to be_nil

    expect(t[:price_table].size).to eq(5)
    expect(t[:price_table]).to include(row: "d2r0", col: "1", amount: "70.0")
  end

  it "prices each run and vehicle" do
    post api_v1_trips_path, params: { trip: shuttle }, as: :json
    get prices_api_v1_trip_path(json.dig(:data, :id)), params: { date: "2026-11-03" }
    expect(json[:data]).to include({ run: "d1r0", slot_no: 2, amount: "55.0" }, { run: "d2r0", slot_no: 2, amount: "0.0" })
    expect(json.dig(:meta, :total)).to eq("285.0")
  end

  it "uses its own return stops when they differ" do
    trip = shuttle.merge(shuttle_separate_return: true, stops_attributes: shuttle[:stops_attributes] + [
      { direction: 2, position: 0, name: "MBC Tower 1", use: "pu" }, { direction: 2, position: 1, name: "HarbourFront MRT", use: "do" }
    ])
    trip[:runs_attributes] = [ shuttle[:runs_attributes][0], { direction: 2, position: 0, times: %w[18:00 18:20] } ]
    trip[:price_table] = []
    post api_v1_trips_path, params: { trip: }, as: :json
    expect(response).to have_http_status(:created)
    expect(json.dig(:data, :runs, 1, :times)).to eq(%w[18:00 18:20])
  end

  describe "route_stops of the way-back run" do
    let(:date) { "2026-11-03" }

    before { travel_to Time.zone.local(2026, 11, 2, 6, 0) }

    def back_stops(trip)
      post api_v1_trips_path, params: { trip: }, as: :json
      expect(response).to have_http_status(:created)
      get api_v1_scheduler_path, params: { from: date }
      (json.dig(:data, :occurrences) + json.dig(:data, :unassigned)).find { it[:start_time] == "18:00" }[:route_stops]
    end

    let(:two_stops) do
      shuttle.merge(shuttle_return: true, price_table: [], runs_attributes: [ shuttle[:runs_attributes][0].merge(times: %w[07:30 07:55]), shuttle[:runs_attributes][2].merge(times: %w[18:00 18:30]) ],
                    stops_attributes: [ { position: 0, name: "ZZ A", use: "pu", return_name: "CBP Bus Bay" }, { position: 1, name: "ZZ B", use: "do" } ])
    end

    it "reverses the stops, swaps pick-up / drop-off and uses the return name" do
      expect(back_stops(two_stops).map { it.slice(:name, :use) }).to eq([ { name: "ZZ B", use: "pu" }, { name: "CBP Bus Bay", use: "do" } ])
    end

    it "keeps the name when the return name is blank" do
      trip = two_stops.merge(stops_attributes: [ { position: 0, name: "ZZ A", use: "pu", return_name: "" }, { position: 1, name: "ZZ B", use: "do" } ])
      expect(back_stops(trip).map { it.slice(:name, :use) }).to eq([ { name: "ZZ B", use: "pu" }, { name: "ZZ A", use: "do" } ])
    end

    it "lists a separate return's own stops as entered" do
      trip = two_stops.merge(shuttle_separate_return: true, stops_attributes: two_stops[:stops_attributes] + [
        { direction: 2, position: 0, name: "MBC Tower 1", use: "pu", return_name: "ignored" }, { direction: 2, position: 1, name: "HarbourFront MRT", use: "do" }
      ])
      expect(back_stops(trip).map { it.slice(:name, :use) }).to eq([ { name: "MBC Tower 1", use: "pu" }, { name: "HarbourFront MRT", use: "do" } ])
    end
  end

  it "checks the timetable like the trip form" do
    bad = shuttle.merge(runs_attributes: [ { direction: 1, position: 0, times: [ "", "07:40", "07:55" ] } ], price_table: [])
    post api_v1_trips_path, params: { trip: bad }, as: :json
    expect(json.dig(:error, :message)).to include("Direction 1, run 1: enter the time at the first stop")

    bad[:runs_attributes] = [ { direction: 1, position: 0, times: %w[07:30 07:20 07:55] } ]
    post api_v1_trips_path, params: { trip: bad }, as: :json
    expect(json.dig(:error, :message)).to include("each stop time must be later than the one before")

    bad[:runs_attributes] = []
    post api_v1_trips_path, params: { trip: bad }, as: :json
    expect(json.dig(:error, :message)).to include("Add at least one shuttle trip time")
  end

  it "removes a run and keeps the others" do
    post api_v1_trips_path, params: { trip: shuttle }, as: :json
    id = json.dig(:data, :id)
    runs = json.dig(:data, :runs)
    patch api_v1_trip_path(id), params: { trip: { runs_attributes: [ { id: runs[1][:id], _destroy: true } ], price_table: [] } }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json.dig(:data, :runs).pluck(:id)).to eq([ runs[0][:id], runs[2][:id] ])
    expect(json.dig(:data, :price_table)).to eq([])
  end

  it "saves a new time on a one-off shuttle by moving that run of the timetable" do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    post api_v1_trips_path, params: { trip: shuttle.merge(starts_on: "2026-11-04", days: [], end_mode: "none") }, as: :json
    id = json.dig(:data, :id)
    get api_v1_occurrences_path, params: { trip_id: id, date: "2026-11-04" }
    occ = json[:data].find { |o| o[:run_key] == "d1r1" && o[:slot_no] == 1 }

    patch time_api_v1_occurrence_path(occ[:id]), params: { scope: "from_here", start_time: "08:40" }, as: :json
    expect(json[:data]).to include(start_time: "08:40", end_time: "09:00", shift_minutes: 0)
    get api_v1_trip_path(id)
    expect(json.dig(:data, :runs).map { |r| r[:times] }).to eq([ %w[07:30 07:40 07:55], [ "08:40", nil, "09:00" ], %w[18:00 18:15 18:25] ])
  end
end
