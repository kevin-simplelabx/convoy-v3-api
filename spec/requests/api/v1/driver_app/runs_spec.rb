require "rails_helper"

# Convoy Driver app › Drive, Plan and Trip Details: the runs of the driver's bus (from the Scheduler's runs), Replaced
# when a replacement took one (the new driver sees it as theirs), New until opened (again after a change of time),
# the points with what was recorded, Point of Contact, the floating on-going trip, and a School Bus run with the school
# as a point, the children, Bus Not Required and QR passes.
RSpec.describe "Driver app runs" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      siti = create(:driver, name: "Siti", phone: "+6598765432")
      a = create(:vehicle, plate: "PD3318K", seats: 23)
      b = create(:vehicle, plate: "PD4472H")
      a.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      b.driver_schedules.create!(driver: siti, starts_on: Date.new(2026, 10, 1))
      { kumar:, siti:, a:, b:, client: create(:client, name: "Google"), type: create(:vehicle_type) }
    end
  end

  before { travel_to Time.zone.local(2026, 11, 2, 6, 0) }

  def create_trip(**attrs)
    sign_in_as(create(:user, :admin, company:))
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", client_id: f[:client].id, starts_on: "2026-11-02", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00", price: 100, trip_value: 1.5, pax: 12, notes: "Wait at the lobby",
      requestor_name: "Priya", requestor_phone: "+6591110000", guest_is_requestor: false, guest_name: "Mr Chen", guest_phone: "+6592220000",
      stops_attributes: [ { position: 0, name: "Jurong East MRT", use: "pu", address: "10 Jurong East St 12", driver_note: "Point B", lat: 1.333, lng: 103.742 },
                          { position: 1, name: "Clementi Ave 6", use: "via", lat: 1.31, lng: 103.77 },
                          { position: 2, name: "Mapletree Business City", use: "do", lat: 1.274, lng: 103.797 } ],
      route_vias_attributes: [ { direction: 1, from_position: 0, position: 0, lat: 1.32, lng: 103.75 } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ],
      vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:a].id } ]
    }.merge(attrs) }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    json.dig(:data, :id)
  end

  def run_on(trip_id, date) = within_tenant(company) { TripOccurrence.find_by!(trip_id:, date:) }

  it "lists the driver's runs, shows Replaced when a replacement took one, and the details" do
    trip = create_trip
    swap = run_on(trip, Date.new(2026, 11, 4))
    post api_v1_replacements_path, params: { occurrence_id: swap.id, replacement: { kind: "crew", vehicle_id: f[:b].id } }, as: :json
    expect(response).to have_http_status(:created), json.inspect

    kumar = driver_token("91234567")
    get api_v1_driver_app_runs_path, params: { from: "2026-11-03", to: "2026-11-04" }, headers: as(kumar)
    expect(json[:data].map { [ it[:date], it[:status] ] }).to eq([ [ "2026-11-03", "scheduled" ], [ "2026-11-04", "replaced" ] ])
    card = json.dig(:data, 0)
    expect(card).to include(start_time: "08:00", end_time: "09:00", kind: "adhoc", kind_label: "Ad Hoc", direction: "One Way",
                            client: { name: "Google", via: nil }, status_label: "Scheduled", seen: false, points_count: 2,
                            first_point: "Jurong East MRT", last_point: "Mapletree Business City", expected_pax: 12,
                            vehicle: hash_including(plate: "PD3318K"), replaced_by: nil)
    expect(json.dig(:data, 1, :replaced_by)).to eq(driver_name: "Siti", vehicle_plate: "PD4472H")

    siti = driver_token("98765432")
    get api_v1_driver_app_runs_path, params: { date: "2026-11-04" }, headers: as(siti)
    expect(json[:data].map { [ it[:id], it[:status], it.dig(:vehicle, :plate) ] }).to eq([ [ swap.id, "scheduled", "PD4472H" ] ])

    kumar = driver_token("91234567")
    run = run_on(trip, Date.new(2026, 11, 3))
    get api_v1_driver_app_run_path(run.id), headers: as(kumar)
    d = json[:data]
    expect(d).to include(trip_value: "1.5", notes: "Wait at the lobby", airport: nil, disposal: nil, series: nil, contractor: nil, replacement: nil,
                         passengers: [], before_you_go: { not_riding: [], skipped_points: [] })
    expect(d[:contacts]).to eq([ { role: "requestor", name: "Priya", phone: "+6591110000" }, { role: "guest", name: "Mr Chen", phone: "+6592220000" } ])
    expect(d[:points].map { [ it[:number], it[:name], it[:planned_time], it[:pickup], it[:dropoff], it[:waypoint] ] }).to eq([
      [ 1, "Jurong East MRT", "08:00", true, false, false ], [ 2, "Clementi Ave 6", nil, false, false, true ],
      [ 3, "Mapletree Business City", nil, false, true, false ]
    ])
    expect(d.dig(:points, 0)).to include(address: "10 Jurong East St 12", note: "Point B", vias: [ { lat: 1.32, lng: 103.75 } ], record: nil)

    get api_v1_driver_app_run_path(swap.id), headers: as(kumar)
    expect(json[:data]).to include(status: "replaced", trip_value: nil, replacement: hash_including(kind: "crew", driver_name: "Siti", vehicle_plate: "PD4472H"))

    get api_v1_driver_app_run_path(0), headers: as(kumar)
    expect(response).to have_http_status(:not_found)
  end

  it "keeps a run New until opened, and New again when its time changes" do
    trip = create_trip
    run = run_on(trip, Date.new(2026, 11, 3))
    kumar = driver_token("91234567")
    post seen_api_v1_driver_app_run_path(run.id), headers: as(kumar)
    expect(json.dig(:data, :seen)).to be(true)

    sign_in_as(create(:user, :admin, company:))
    within_tenant(company) { Trips::Save.call(trip: Trip.find(trip), attributes: { start_time: "08:30", end_time: "09:30" }, user: User.last) }
    get api_v1_driver_app_runs_path, params: { date: "2026-11-03" }, headers: as(kumar)
    expect(json.dig(:data, 0)).to include(start_time: "08:30", seen: false)
  end

  it "gives the Plan calendar days and the on-going trip" do
    trip = create_trip
    kumar = driver_token("91234567")
    get schedule_api_v1_driver_app_runs_path, params: { month: "2026-11" }, headers: as(kumar)
    expect(json.dig(:data, :days).first(3)).to eq([ { date: "2026-11-02", runs: 1 }, { date: "2026-11-03", runs: 1 }, { date: "2026-11-04", runs: 1 } ])
    get schedule_api_v1_driver_app_runs_path, params: { month: "11/2026" }, headers: as(kumar)
    expect(json.dig(:error, :message)).to eq("Dates are YYYY-MM-DD, months YYYY-MM")

    get on_going_api_v1_driver_app_runs_path, headers: as(kumar)
    expect(json[:data]).to be_nil
    travel_to Time.zone.local(2026, 11, 2, 7, 40)
    within_tenant(company) { Occurrences::DriverProgress.call(run_on(trip, Date.new(2026, 11, 2)), :start) }
    get on_going_api_v1_driver_app_runs_path, headers: as(kumar)
    expect(json[:data]).to include(status: "on_the_way", date: "2026-11-02")

    get api_v1_driver_app_runs_path, params: { from: "2026-11-01", to: "2026-12-15" }, headers: as(kumar)
    expect(json.dig(:error, :message)).to eq("Ask for 31 days at most")
  end

  describe "a School Bus run" do
    let!(:school_bus) do
      within_tenant(company) do
        school = School.create!(name: "St. Stephen's School", short_name: "SSS", lat: 1.3138, lng: 103.9283, address: "20 Siglap View", postal: "455789")
        year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
        year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
        %w[S-1 S-2 S-3].each_with_index do |rid, i|
          school.riders.create!(rid:, name: "Child #{i + 1}", grade: "P#{i + 1}", postal: "46012#{i}", am: true, pm: true, source: "manual",
                                parent_name: "Parent #{i + 1}", parent_contact: "+659000000#{i}")
        end
        am = school.plans.create!(name: "Term 4 AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
        route = am.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20", bus_type: "LARGE_40", seats: 40)
        library = Stop.new(code: "BDSZ03-0001", subzone_code: "BDSZ03", name: "Blk 101 Bedok North")
        library.all_points.build(suffix: "A", usage: "both", sizes: %w[S M L], primary: true, lat: 1.3305, lng: 103.9373,
                                 street_view_url: "https://maps.google.com/?cbll=1.3305,103.9373", photo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/photo.png"), "image/png"))
        library.save!
        s1 = route.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "06:30", lat: 1.3305, lng: 103.9373, stop: library)
        s2 = route.stops.create!(position: 1, name: "Blk 32 Siglap", scheduled_time: "06:45", lat: 1.3136, lng: 103.9247)
        [ [ s1, "S-1" ], [ s1, "S-2" ], [ s2, "S-3" ] ].each { |s, rid| SchoolRouteRider.create!(school_route: route, stop: s, rid:) }
        route.vehicle_changes.create!(vehicle: f[:a], effective_from: Date.new(2026, 10, 1))
        school.rider_absences.create!(rid: "S-2", date: Date.new(2026, 11, 3), trip: "am", reason: "sick", note: "Fever", reported_by: "Parent")
        Occurrences::Sync.call(routes: [ route ])
        route
      end
    end

    it "has the school as the last point, the children with their points and passes, and Before You Go" do
      kumar = driver_token("91234567")
      get api_v1_driver_app_runs_path, params: { date: "2026-11-03" }, headers: as(kumar)
      card = json[:data].find { it[:kind] == "school" }
      expect(card).to include(title: "SSS AM 1", direction: "To School", client: { name: "St. Stephen's School", via: nil }, points_count: 3,
                              last_point: "St. Stephen's School", expected_pax: 2, requires: "attendance")

      get api_v1_driver_app_run_path(card[:id]), headers: as(kumar)
      d = json[:data]
      expect(d[:points].map { [ it[:position], it[:name], it[:planned_time], it[:pickup], it[:dropoff], it[:school], it[:pickups], it[:dropoffs] ] }).to eq([
        [ 0, "Blk 101 Bedok North", "06:30", true, false, false, 2, 0 ], [ 1, "Blk 32 Siglap", "06:45", true, false, false, 1, 0 ],
        [ 2, "St. Stephen's School", "07:20", false, true, true, 0, 3 ]
      ])
      expect(d.dig(:points, 2, :address)).to eq("20 Siglap View, Singapore 455789")
      expect(d.dig(:points, 0)).to include(street_view_url: "https://maps.google.com/?cbll=1.3305,103.9373", photos: [ hash_including(:url, :thumb_url) ])
      expect(d.dig(:points, 1)).to include(street_view_url: nil, photos: [])
      expect(d[:passengers].map { [ it[:id], it[:state], it[:pickup_position], it[:dropoff_position] ] })
        .to eq([ [ "S-1", "expected", 0, 2 ], [ "S-2", "bus_not_required", 0, 2 ], [ "S-3", "expected", 1, 2 ] ])
      expect(d[:passengers].first).to include(name: "Child 1", level: "P1", parent_name: "Parent 1", parent_phone: "+6590000000")
      expect(DriverApp::RiderPass.rid(company.id, d.dig(:passengers, 0, :qr_code))).to eq("S-1")
      expect(DriverApp::RiderPass.rid(company.id + 1, d.dig(:passengers, 0, :qr_code))).to be_nil
      expect(d[:before_you_go][:not_riding]).to eq([ { id: "S-2", name: "Child 2", point: "Blk 101 Bedok North", state: "bus_not_required", reason: "Unwell. Fever" } ])
      expect(d[:expected_pax]).to eq(2)
    end
  end
end
