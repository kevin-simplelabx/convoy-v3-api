require "rails_helper"

# Fleet > Vehicles and Transport Operators > Operator Vehicles.
RSpec.describe "Fleet vehicles" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      east = create(:vehicle_team, name: "East", color: "#004F59")
      west = create(:vehicle_team, name: "West", color: "#2F7FA8")
      hup = create(:operator, name: "Hup Seng")
      {
        east:, west:, hup:, client: create(:client), type: create(:vehicle_type),
        van: create(:vehicle, plate: "PD1A", seats: 13, vehicle_team: east),
        bus: create(:vehicle, plate: "PD2B", seats: 23, vehicle_team: east),
        car: create(:vehicle, plate: "PD3C", seats: 4),
        op1: create(:vehicle, plate: "PC1X", seats: 23, operator: hup),
        op2: create(:vehicle, plate: "PC2Y", seats: 40, operator: hup)
      }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 6, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  describe "list" do
    it "gives team chips for the ownership picked and filters by team" do
      get api_v1_vehicles_path, params: { ownership: %w[own] }
      teams = json.dig(:meta, :facets, :teams)
      expect(teams).to include(all: 3, none: 1)
      expect(teams[:list]).to eq([ { id: f[:east].id, name: "East", color: "#004F59", count: 2 },
                                   { id: f[:west].id, name: "West", color: "#2F7FA8", count: 0 } ])

      get api_v1_vehicles_path, params: { ownership: %w[own], team_id: "none" }
      expect(json[:data].pluck(:plate)).to eq(%w[PD3C])

      get api_v1_vehicles_path, params: { ownership: %w[managed] }
      expect(json[:data].pluck(:plate)).to eq(%w[PC1X PC2Y])
      expect(json.dig(:meta, :facets, :teams)).to include(all: 2, none: 2)
    end

    it "searches by team, default driver and operator driver" do
      within_tenant(company) do
        f[:car].driver_schedules.create!(driver: create(:driver, name: "Eric Pang"), starts_on: Date.current - 3)
        f[:car].driver_schedules.create!(driver: create(:driver, name: "Later Lim"), starts_on: Date.current + 3)
        create(:operator_driver, operator: f[:hup], name: "Muthu", vehicle: f[:op2])
      end

      get api_v1_vehicles_path, params: { q: "east" }
      expect(json[:data].pluck(:plate)).to eq(%w[PD1A PD2B])
      get api_v1_vehicles_path, params: { q: "eric" }
      expect(json[:data].pluck(:plate)).to eq(%w[PD3C])
      get api_v1_vehicles_path, params: { q: "later" }
      expect(json[:data]).to be_empty
      get api_v1_vehicles_path, params: { q: "muthu" }
      expect(json[:data].pluck(:plate)).to eq(%w[PC2Y])
    end
  end

  describe "Manage Teams" do
    it "renames, swaps names, adds and deletes in one save" do
      put bulk_api_v1_vehicle_teams_path, params: { teams: [
        { id: f[:east].id, name: "West", color: "#5B2A6E" },
        { id: f[:west].id, name: "East" },
        { name: "Coaches", color: "#1E5631" }
      ] }, as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data].pluck(:name)).to eq(%w[West East Coaches])
      expect(within_tenant(company) { f[:van].reload.vehicle_team.name }).to eq("West")

      put bulk_api_v1_vehicle_teams_path, params: { teams: [ { id: f[:west].id, name: "East" } ] }, as: :json
      expect(f[:van].reload.vehicle_team_id).to be_nil
      expect(within_tenant(company) { VehicleTeam.count }).to eq(1)
    end

    it "refuses empty and duplicate names" do
      put bulk_api_v1_vehicle_teams_path, params: { teams: [ { name: "A" }, { name: " a " } ] }, as: :json
      expect(json.dig(:error, :message)).to eq("Two teams have the same name")
      put bulk_api_v1_vehicle_teams_path, params: { teams: [ { name: "" } ] }, as: :json
      expect(json.dig(:error, :message)).to eq("Give every team a name")
    end
  end

  describe "record" do
    it "shows upcoming driver changes and the financials summary" do
      within_tenant(company) { f[:van].driver_schedules.create!(driver: create(:driver, name: "Tan"), starts_on: Date.current + 5) }
      get api_v1_vehicle_path(f[:van])
      expect(json[:data]).to include(financials: { status: "no_details" }) # the signed-in admin has vehfin
      expect(json.dig(:data, :fuel)).to include(entries: 0, last: nil)
      expect(json.dig(:data, :upcoming_drivers)).to eq([ { starts_on: (Date.current + 5).iso8601, driver: { id: Driver.unscoped.last.id, name: "Tan" } } ])
    end
  end

  describe "delete" do
    it "is refused while the bus has runs from now on" do
      post api_v1_trips_path, params: { trip: {
        kind: "ad_hoc", client_id: f[:client].id, starts_on: "2026-11-03", start_time: "08:00", end_time: "09:00", pax: 5,
        stops_attributes: [ { position: 0, name: "A", use: "pu" }, { position: 1, name: "B", use: "do" } ],
        vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ],
        vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:van].id } ]
      } }, as: :json
      expect(response).to have_http_status(:created)

      delete api_v1_vehicle_path(f[:van])
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("PD1A still has 1 run from now on. Move or cancel them first, then delete the vehicle")

      delete api_v1_vehicle_path(f[:car])
      expect(response).to have_http_status(:no_content)
    end

    it "takes the operator driver off the bus" do
      d = within_tenant(company) { create(:operator_driver, operator: f[:hup], vehicle: f[:op1]) }
      delete api_v1_vehicle_path(f[:op1])
      expect(d.reload.vehicle_id).to be_nil
    end
  end

  describe "operator driver change preview" do
    let!(:d) do
      within_tenant(company) do
        { a: create(:operator_driver, operator: f[:hup], name: "Ali", vehicle: f[:op1]),
          b: create(:operator_driver, operator: f[:hup], name: "Bala", vehicle: f[:op2]),
          c: create(:operator_driver, operator: f[:hup], name: "Chen") }
      end
    end

    it "explains a swap, a move, and taking a driver off" do
      get assign_preview_api_v1_operator_drivers_path, params: { driver_id: d[:a].id, vehicle_id: f[:op2].id }
      expect(json[:data]).to include(swap: true, ok_label: "Swap Drivers", effects: [ "Ali moves from PC1X to PC2Y", "Bala moves to PC1X" ])

      get assign_preview_api_v1_operator_drivers_path, params: { driver_id: d[:c].id, vehicle_id: f[:op1].id }
      expect(json[:data]).to include(swap: false, effects: [ "Chen drives PC1X", "Ali is left without a bus" ],
                                     apply: { driver_id: d[:c].id, vehicle_id: f[:op1].id })

      get assign_preview_api_v1_operator_drivers_path, params: { vehicle_id: f[:op1].id }
      expect(json[:data]).to include(effects: [ "Ali is taken off PC1X" ], apply: { driver_id: d[:a].id, vehicle_id: nil })
    end

    it "refuses a bus of another operator" do
      other = within_tenant(company) { create(:vehicle, plate: "PX9", operator: create(:operator, name: "Other")) }
      get assign_preview_api_v1_operator_drivers_path, params: { driver_id: d[:c].id, vehicle_id: other.id }
      expect(json.dig(:error, :message)).to eq("PX9 is not a bus of Hup Seng")
    end
  end
end
