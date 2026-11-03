require "rails_helper"

# Convoy Driver app › Switch Vehicle: the office moves the driver to another bus from 06:30 (Edit Vehicle, default
# driver from a time); Drive shows the switch card; the handover takes all six photos (one marked up) and the
# declaration, once per client_id; My Vehicle Today follows the time; Vehicle History lists the buses driven.
RSpec.describe "Driver app vehicle switch" do
  include ActionDispatch::TestProcess::FixtureFile

  let(:company) { create(:company, name: "SimpleDrive") }
  let(:day) { Date.new(2026, 11, 3) }
  let!(:f) do
    within_tenant(company) do
      ahmad = create(:driver, name: "Ahmad", phone: "+6591234567")
      old_bus = create(:vehicle, plate: "PC8812K")
      new_bus = create(:vehicle, plate: "PC1234X")
      other = create(:vehicle, plate: "PD9999Z")
      old_bus.driver_schedules.create!(driver: ahmad, starts_on: Date.new(2026, 10, 1))
      new_bus.driver_schedules.create!(driver: ahmad, starts_on: day, start_time: "06:30")
      old_bus.driver_schedules.create!(driver: nil, starts_on: day, start_time: "06:30")
      [ [ old_bus, 360 ], [ new_bus, 480 ] ].each_with_index do |(bus, start), i|
        trip = create(:trip, start_time: Clock.hm(start), end_time: Clock.hm(start + 40), starts_on: day)
        trip.vehicle_slots.create!(slot_no: 1, vehicle: bus)
        Occurrences::Sync.call(trips: [ trip ])
        TripOccurrence.find_by!(trip:).update_columns(status: "completed") if i.zero?
      end
      { ahmad:, old_bus:, new_bus:, other: }
    end
  end

  def photos(skip: nil)
    VehicleHandover::SIDES.reject { it == skip }.index_with { fixture_file_upload("photo.png", "image/png") }
  end

  it "shows the switch, takes the handover once, and follows the time for the bus today" do
    travel_to Time.zone.local(2026, 11, 3, 6, 0)
    token = driver_token("91234567")

    get api_v1_driver_app_vehicle_path, headers: as(token)
    expect(json.dig(:data, :current)).to include(plate: "PC8812K")
    expect(json.dig(:data, :switches).map { [ it.dig(:vehicle, :plate), Time.zone.parse(it[:starts_at]), it[:handover_done] ] })
      .to eq([ [ "PC1234X", Time.zone.local(2026, 11, 3, 6, 30), false ] ])
    get api_v1_driver_app_runs_path, headers: as(token)
    expect(json[:data].map { it.dig(:vehicle, :plate) }).to eq(%w[PC8812K PC1234X])
    expect(json.dig(:meta, :vehicle_switches, 0)).to include(vehicle: { id: f[:new_bus].id, plate: "PC1234X" }, handover_done: false)

    id = SecureRandom.uuid
    post api_v1_driver_app_vehicle_handovers_path, params: { client_id: id, vehicle_id: f[:new_bus].id, photos: photos(skip: "inside"), declaration: true }, headers: as(token)
    expect(json[:error]).to include(code: "photos_needed", details: { missing: [ "inside" ] })
    post api_v1_driver_app_vehicle_handovers_path, params: { client_id: id, vehicle_id: f[:new_bus].id, photos: photos }, headers: as(token)
    expect(json.dig(:error, :code)).to eq("declaration_needed")
    post api_v1_driver_app_vehicle_handovers_path, params: { client_id: id, vehicle_id: f[:other].id, photos:, declaration: true }, headers: as(token)
    expect(json.dig(:error, :code)).to eq("not_your_bus")

    params = { client_id: id, vehicle_id: f[:new_bus].id, photos:, declaration: true, note: "Scratch on the rear bumper",
               marked: { back: fixture_file_upload("photo.png", "image/png") }, marks: { back: [ { kind: "circle", x: 120, y: 200, r: 30 } ].to_json } }
    post api_v1_driver_app_vehicle_handovers_path, params:, headers: as(token)
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(vehicle: { id: f[:new_bus].id, plate: "PC1234X" }, note: "Scratch on the rear bumper")
    expect(json.dig(:data, :photos).pluck(:side, :label)).to eq(VehicleHandover::SIDES.zip(VehicleHandover::SIDE_LABELS.values))
    back = json.dig(:data, :photos).find { it[:side] == "back" }
    expect(back).to include(marked_photo: hash_including(:url), marks: [ { kind: "circle", x: 120, y: 200, r: 30 } ])
    post api_v1_driver_app_vehicle_handovers_path, params:, headers: as(token)
    expect(json[:meta]).to eq(replayed: true)
    expect(within_tenant(company) { VehicleHandover.count }).to eq(1)

    get api_v1_driver_app_runs_path, headers: as(token)
    expect(json.dig(:meta, :vehicle_switches, 0, :handover_done)).to be(true)

    travel_to Time.zone.local(2026, 11, 3, 7, 0)
    get api_v1_driver_app_vehicle_path, headers: as(token)
    expect(json[:data]).to include(switches: [], handovers: [ hash_including(vehicle: { id: f[:new_bus].id, plate: "PC1234X" }) ])
    expect(json.dig(:data, :current)).to include(plate: "PC1234X", since: "2026-11-03", since_time: "06:30")

    get history_api_v1_driver_app_vehicle_path, params: { month: "2026-11" }, headers: as(token)
    expect(json.dig(:data, :days)).to eq([ { date: "2026-11-03", vehicles: [ { id: f[:old_bus].id, plate: "PC8812K", runs: 1 },
                                                                            { id: f[:new_bus].id, plate: "PC1234X", runs: 1 } ] } ])
    expect(json.dig(:data, :handovers).size).to eq(1)
  end
end
