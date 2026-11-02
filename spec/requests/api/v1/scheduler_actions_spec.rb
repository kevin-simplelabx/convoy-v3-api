require "rails_helper"

RSpec.describe "Scheduler drops and assignments" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      hup = create(:operator, name: "Hup Seng", valid_until: Date.new(2026, 11, 20))
      {
        own: create(:vehicle, plate: "PD3318K", seats: 13), own2: create(:vehicle, plate: "PD4472H", seats: 13),
        managed: create(:vehicle, plate: "PC7475L", seats: 23, operator: hup), small: create(:vehicle, plate: "SX1", seats: 4),
        hup:, client: create(:client, name: "Google"), type: create(:vehicle_type)
      }
    end
  end

  def stops = [ { position: 0, name: "A", use: "pu" }, { position: 1, name: "B", use: "do" } ]

  def create_trip(**attrs)
    trip = { kind: "ad_hoc", client_id: f[:client].id, starts_on: "2026-11-02", start_time: "08:00", end_time: "09:00", pax: 10,
             stops_attributes: stops, vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ],
             vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:own].id } ] }.merge(attrs)
    post api_v1_trips_path, params: { trip: }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    json.dig(:data, :id)
  end

  def run(trip_id, date, run_key: nil)
    get api_v1_occurrences_path, params: { trip_id:, date: }
    json[:data].find { |o| run_key.nil? || o[:run_key] == run_key }
  end

  def plates(trip_id, from, to)
    get api_v1_occurrences_path, params: { trip_id:, from:, to: }
    json[:data].map { |o| o[:plate] }
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    sign_in_as(create(:user, company:))
  end

  it "moves a one-off trip by changing the trip's own bus" do
    id = create_trip(starts_on: "2026-11-04")
    occ = run(id, "2026-11-04")
    post move_api_v1_occurrence_path(occ[:id]), params: { vehicle_id: f[:own2].id, scope: "one" }, as: :json
    expect(json[:data].first).to include(plate: "PD4472H", overridden_fields: [])
    get api_v1_trip_path(id)
    expect(json.dig(:data, :vehicle_slots, 0, :plate)).to eq("PD4472H")
  end

  it "moves a recurring run for one date or from that date on (as an assignment)" do
    id = create_trip(days: [ 1, 2, 3, 4, 5 ], end_mode: "never")
    post move_api_v1_occurrence_path(run(id, "2026-11-03")[:id]), params: { vehicle_id: f[:own2].id, scope: "one" }, as: :json
    expect(plates(id, "2026-11-02", "2026-11-04")).to eq(%w[PD3318K PD4472H PD3318K])

    post move_api_v1_occurrence_path(run(id, "2026-11-05")[:id]), params: { vehicle_id: f[:managed].id, scope: "later", cost: 90 }, as: :json
    expect(plates(id, "2026-11-02", "2026-11-09")).to eq(%w[PD3318K PD4472H PD3318K PC7475L PC7475L PC7475L])
    expect(run(id, "2026-11-06")).to include(operator_cost: "90.0", operator_id: f[:hup].id)

    get api_v1_trip_assignments_path(id), params: { from: "2026-11-06" }
    expect(json.dig(:data, :slots, 0)).to include(key: "trip|1", assignee: "operator", plate: "PC7475L", pay_amount: "90.0")
    expect(json.dig(:data, :history, 0)).to include(effective_from: "2026-11-05", slots: [ "trip|1" ])
  end

  it "warns before a drop and prefills the operator's agreed pay" do
    id = create_trip(days: [ 1, 2, 3, 4, 5 ], end_mode: "never", pax: 12)
    other = create_trip(starts_on: "2026-11-23", start_time: "08:30", end_time: "09:30", vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:small].id } ])
    expect(other).to be_present
    post move_api_v1_occurrence_path(run(id, "2026-11-05")[:id]), params: { vehicle_id: f[:managed].id, scope: "later", cost: 95 }, as: :json

    get move_preview_api_v1_occurrence_path(run(id, "2026-11-23")[:id]), params: { vehicle_id: f[:small].id }
    expect(json.dig(:data, :warnings).first).to start_with("SX1 already has Google at 08:30–09:30")
    expect(json.dig(:data, :warnings).last).to eq("SX1 has 4 seats. This trip has 12 passengers")
    expect(json.dig(:data, :scopes)).to eq(%w[one later])

    get move_preview_api_v1_occurrence_path(run(id, "2026-11-23")[:id]), params: { vehicle_id: f[:managed].id }
    expect(json.dig(:data, :warnings)).to eq([ "Hup Seng is set as valid until 20/11/2026" ])
    expect(json.dig(:data, :cost)).to include(amount: "95.0", basis: "run", source: "agreed")
  end

  it "charges a disposal by the hour on an operator bus and unassigns a run" do
    id = create_trip(kind: "disposal", hours: 4, end_time: nil, starts_on: "2026-11-05", stops_attributes: [ { position: 0, name: "A", use: "pu" } ])
    post move_api_v1_occurrence_path(run(id, "2026-11-05")[:id]), params: { vehicle_id: f[:managed].id, scope: "one", cost: 40, cost_basis: "hour" }, as: :json
    expect(json[:data].first).to include(plate: "PC7475L", operator_cost: "160.0")

    rec = create_trip(days: [ 1, 2, 3, 4, 5 ], end_mode: "never")
    post move_api_v1_occurrence_path(run(rec, "2026-11-04")[:id]), params: { vehicle_id: nil, scope: "one" }, as: :json
    get api_v1_scheduler_path, params: { from: "2026-11-04" }
    expect(json.dig(:data, :unassigned).pluck(:trip_id)).to include(rec)
  end

  it "takes the bus back with Back to Regular Bus" do
    id = create_trip(days: [ 1, 2, 3, 4, 5 ], end_mode: "never")
    occ = run(id, "2026-11-04")
    post move_api_v1_occurrence_path(occ[:id]), params: { vehicle_id: f[:own2].id, scope: "one" }, as: :json
    patch regular_bus_api_v1_occurrence_path(occ[:id]), as: :json
    expect(json[:data]).to include(plate: "PD3318K", overridden_fields: [])
  end

  describe "shuttles" do
    let(:shuttle_id) do
      create_trip(
        kind: "corporate_shuttle", days: [ 1, 2, 3, 4, 5 ], end_mode: "never", vehicle_slots_attributes: [],
        runs_attributes: [
          { direction: 1, position: 0, times: %w[07:30 08:00], slots_attributes: [ { slot_no: 1, vehicle_id: f[:own].id, group_key: "am" } ] },
          { direction: 1, position: 1, times: %w[08:30 09:00], slots_attributes: [ { slot_no: 1, vehicle_id: f[:own].id, group_key: "am" } ] },
          { direction: 1, position: 2, times: %w[17:30 18:00], slots_attributes: [ { slot_no: 1, vehicle_id: f[:own].id } ] }
        ]
      )
    end

    it "moves grouped runs together and spreads a daily pay over them" do
      occ = run(shuttle_id, "2026-11-04", run_key: "d1r0")
      post move_api_v1_occurrence_path(occ[:id]), params: { vehicle_id: f[:managed].id, scope: "one", cost: 200, cost_basis: "day" }, as: :json
      expect(json[:data].map { |o| [ o[:run_key], o[:plate], o[:operator_cost] ] }).to eq([ [ "d1r0", "PC7475L", "100.0" ], [ "d1r1", "PC7475L", "100.0" ] ])
      expect(run(shuttle_id, "2026-11-04", run_key: "d1r2")[:plate]).to eq("PD3318K")
    end

    it "names an operator before the bus is known, with pay per month spread over the runs" do
      post api_v1_trip_assignments_path(shuttle_id), params: {
        effective_from: "2026-11-09", slots: %w[d1r0|1 d1r1|1 d1r2|1], assignee: "operator", operator_id: f[:hup].id,
        pay_amount: 6300, pay_basis: "month"
      }, as: :json
      expect(response).to have_http_status(:created)
      occ = run(shuttle_id, "2026-11-10", run_key: "d1r0")
      # November from the 9th still runs 16 days of the month's 21 weekdays: 6300 / 3 runs / 21 days
      expect(occ).to include(vehicle_id: nil, operator_id: f[:hup].id, operator_cost: "100.0")

      get assign_summary_api_v1_scheduler_path
      expect(json[:data].first).to include(trip_id: shuttle_id, assigned: 3, total: 3, status: "all")

      get api_v1_trip_assignments_path(shuttle_id)
      delete api_v1_trip_assignment_path(shuttle_id, json.dig(:data, :history, 0, :id))
      expect(run(shuttle_id, "2026-11-10", run_key: "d1r0")).to include(plate: "PD3318K", operator_id: nil)
    end

    it "groups and ungroups runs from the drawer" do
      expect(run(shuttle_id, "2026-11-04", run_key: "d1r2")[:group_key]).to be_nil
      post api_v1_trip_run_groups_path(shuttle_id), params: { slots: %w[d1r1|1 d1r2|1] }, as: :json
      key = json.dig(:data, :group_key)
      expect(run(shuttle_id, "2026-11-04", run_key: "d1r2")[:group_key]).to eq(key)
      expect(run(shuttle_id, "2026-11-04", run_key: "d1r0")[:group_key]).to be_nil # its old group of one is gone

      delete api_v1_trip_run_group_path(shuttle_id, key.delete_prefix("g"))
      expect(run(shuttle_id, "2026-11-04", run_key: "d1r1")[:group_key]).to be_nil
    end
  end

  # .notes/domains/occurrences.md (Layer model): each layer kept apart, any undo order gives the right result.
  it "keeps assign, cancel and a hand move apart when the assignment is removed" do
    id = create_trip(days: [ 1, 2, 3, 4, 5 ], end_mode: "never")
    post api_v1_trip_assignments_path(id), params: { effective_from: "2026-11-02", slots: %w[trip|1], assignee: "operator",
                                                      operator_id: f[:hup].id, vehicle_id: f[:managed].id }, as: :json
    patch cancel_api_v1_occurrence_path(run(id, "2026-11-04")[:id]), as: :json
    post move_api_v1_occurrence_path(run(id, "2026-11-05")[:id]), params: { vehicle_id: f[:own2].id, scope: "one" }, as: :json
    expect(plates(id, "2026-11-03", "2026-11-06")).to eq(%w[PC7475L PC7475L PD4472H PC7475L])

    get api_v1_trip_assignments_path(id)
    delete api_v1_trip_assignment_path(id, json.dig(:data, :history, 0, :id))
    expect(plates(id, "2026-11-03", "2026-11-06")).to eq(%w[PD3318K PD3318K PD4472H PD3318K])
    expect(run(id, "2026-11-04")[:status]).to eq("cancelled")
  end
end
