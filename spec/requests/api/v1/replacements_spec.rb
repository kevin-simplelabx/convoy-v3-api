require "rails_helper"

RSpec.describe "Replacements" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      hup = create(:operator, name: "Hup Seng")
      kumar = create(:driver, name: "Kumar")
      siti = create(:driver, name: "Siti")
      a = create(:vehicle, plate: "PD3318K")
      b = create(:vehicle, plate: "PD4472H")
      a.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      b.driver_schedules.create!(driver: siti, starts_on: Date.new(2026, 10, 1))
      { a:, b:, c: create(:vehicle, plate: "PE1290S"), managed: create(:vehicle, plate: "PC7475L", operator: hup), hup:, kumar:, siti:,
        client: create(:client, name: "Google"), type: create(:vehicle_type) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    sign_in_as(create(:user, company:))
  end

  def create_trip(vehicle: f[:a], **attrs)
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", client_id: f[:client].id, starts_on: "2026-10-26", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00", price: 100, trip_value: 1,
      stops_attributes: [ { position: 0, name: "Jurong East", use: "pu" }, { position: 1, name: "MBC", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ],
      vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: vehicle.id } ]
    }.merge(attrs) }, as: :json
    json.dig(:data, :id)
  end

  def runs(trip_id, from, to)
    get api_v1_occurrences_path, params: { trip_id:, from:, to: }
    json[:data]
  end

  def run_id(trip_id, date) = runs(trip_id, date, date).first[:id]

  def replace(occurrence_id: nil, notify: nil, **rep)
    post api_v1_replacements_path, params: { occurrence_id:, replacement: rep, notify: }.compact, as: :json
    json
  end

  it "Driver Unavailable on one run puts the new driver on the same bus, and goes back when removed" do
    id = create_trip
    r = replace(occurrence_id: run_id(id, "2026-11-04"), kind: "drv", driver_name: "Ah Kow", driver_phone: "91112222")
    expect(response).to have_http_status(:created)
    expect(r[:data]).to include(summary: "Ah Kow (91112222) drives PD3318K. This trip on 04/11/2026.",
                                pay_text: "Trip value goes to Ah Kow, the replacement driver")

    day = runs(id, "2026-11-03", "2026-11-04")
    expect(day.map { |o| [ o[:plate], o.dig(:driver, :name) ] }).to eq([ %w[PD3318K Kumar], [ "PD3318K", "Ah Kow" ] ])

    delete api_v1_replacement_path(r.dig(:data, :id))
    expect(runs(id, "2026-11-04", "2026-11-04").first.dig(:driver, :name)).to eq("Kumar")
  end

  it "Vehicle Down for a date range moves the bus's runs with their own driver, leaving a ghost" do
    id = create_trip
    replace(kind: "veh", scope: "range", original_vehicle_id: f[:a].id, starts_on: "2026-11-04", ends_on: "2026-11-05", vehicle_id: f[:c].id)
    rows = runs(id, "2026-11-03", "2026-11-06")
    expect(rows.map { |o| [ o[:plate], o[:original_plate], o.dig(:driver, :name) ] }).to eq([
      [ "PD3318K", nil, "Kumar" ], [ "PE1290S", "PD3318K", "Kumar" ], [ "PE1290S", "PD3318K", "Kumar" ], [ "PD3318K", nil, "Kumar" ]
    ])
    expect(rows[1][:grid_status]).to eq("replacement")
    get api_v1_replacements_path, params: { vehicle_id: f[:a].id }
    expect(json[:data].first).to include(status_label: "Coming Up", kind_name: "Vehicle Down")
  end

  it "Crew Swap takes the new bus and its driver" do
    id = create_trip
    replace(occurrence_id: run_id(id, "2026-11-04"), kind: "crew", vehicle_id: f[:b].id, eta: "08:10")
    expect(runs(id, "2026-11-04", "2026-11-04").first).to include(plate: "PD4472H", original_plate: "PD3318K")
    expect(runs(id, "2026-11-04", "2026-11-04").first.dig(:driver, :name)).to eq("Siti")
  end

  it "a handover splits the run and the trip value" do
    id = create_trip
    occ = run_id(id, "2026-11-04")
    replace(occurrence_id: occ, kind: "hand", vehicle_id: f[:b].id, handover_stop: "Clementi", handover_time: "09:30",
            pay_split: "split", original_share: 60)
    expect(json.dig(:error, :message)).to eq("The handover time must be during the trip, 08:00 to 09:00")

    replace(occurrence_id: occ, kind: "hand", vehicle_id: f[:b].id, handover_stop: "Clementi", handover_time: "08:20",
            pay_split: "split", original_share: 60)
    parts = runs(id, "2026-11-04", "2026-11-04").sort_by { |o| o[:part] }
    expect(parts.map { |o| [ o[:part], o[:plate], o[:start_time], o[:end_time], o[:trip_value], o[:price] ] }).to eq([
      [ 1, "PD3318K", "08:00", "08:20", "0.6", "100.0" ], [ 2, "PD4472H", "08:20", "09:00", "0.4", "0.0" ]
    ])
    expect(parts.last.dig(:driver, :name)).to eq("Siti")
  end

  it "when we arrange the new bus for an operator's run, previews the deduction and records who was told" do
    id = create_trip(vehicle: f[:managed], operator_cost: 120)
    occ = run_id(id, "2026-11-04")
    get preview_api_v1_replacements_path, params: { occurrence_id: occ, replacement: { kind: "crew", vehicle_id: f[:b].id, arranged_by: "us" } }
    expect(json[:data]).to include(affected: 1, deduction_default: "120.0", operator: { id: f[:hup].id, name: "Hup Seng" })
    expect(json.dig(:data, :message)).to start_with("Convoy update: Google on 04/11/2026. Your bus is now PD4472H, driven by Siti")

    replace(occurrence_id: occ, kind: "crew", vehicle_id: f[:b].id, arranged_by: "us", deduction: 120, premium: 30,
            notify: { audiences: [ "guests" ], channels: [ "push" ] })
    expect(json.dig(:error, :message)).to include("Convoy App messages go to parents only")

    r = replace(occurrence_id: occ, kind: "crew", vehicle_id: f[:b].id, arranged_by: "us", deduction: 120, premium: 30,
                notify: { audiences: [ "guests" ], channels: [ "email" ] })
    expect(r.dig(:data, :notifications, 0)).to include(audiences: [ "guests" ], channels: [ "email" ])
    expect(runs(id, "2026-11-04", "2026-11-04").first).to include(plate: "PD4472H", operator_id: nil)
  end

  # .notes/domains/occurrences.md (Layer model), step by step.
  it "keeps every layer apart through assign, replace, cancel, move, unassign and Vehicle Down" do
    id = create_trip
    post api_v1_trip_assignments_path(id), params: { effective_from: "2026-11-02", slots: %w[trip|1], assignee: "own", vehicle_id: f[:b].id }, as: :json
    replace(occurrence_id: run_id(id, "2026-11-05"), kind: "drv", driver_name: "Driver X")
    patch cancel_api_v1_occurrence_path(run_id(id, "2026-11-06")), as: :json
    post move_api_v1_occurrence_path(run_id(id, "2026-11-09")), params: { vehicle_id: f[:c].id, scope: "one" }, as: :json

    look = -> { runs(id, "2026-11-04", "2026-11-12").map { |o| [ o[:date][5..], o[:plate], o.dig(:driver, :name), o[:status] ] } }
    expect(look.call.first(4)).to eq([
      [ "11-04", "PD4472H", "Siti", "scheduled" ], [ "11-05", "PD4472H", "Driver X", "scheduled" ],
      [ "11-06", "PD4472H", "Siti", "cancelled" ], [ "11-09", "PE1290S", nil, "scheduled" ]
    ])

    get api_v1_trip_assignments_path(id)
    delete api_v1_trip_assignment_path(id, json.dig(:data, :history, 0, :id))
    replace(kind: "veh", scope: "range", original_vehicle_id: f[:a].id, starts_on: "2026-11-10", ends_on: "2026-11-12", vehicle_id: f[:managed].id)

    expect(look.call).to eq([
      [ "11-04", "PD3318K", "Kumar", "scheduled" ], [ "11-05", "PD3318K", "Driver X", "scheduled" ],
      [ "11-06", "PD3318K", "Kumar", "cancelled" ], [ "11-09", "PE1290S", nil, "scheduled" ],
      [ "11-10", "PC7475L", "Kumar", "scheduled" ], [ "11-11", "PC7475L", "Kumar", "scheduled" ], [ "11-12", "PC7475L", "Kumar", "scheduled" ]
    ])
  end
end
