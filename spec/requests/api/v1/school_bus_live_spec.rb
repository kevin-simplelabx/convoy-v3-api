require "rails_helper"

# School Bus › Live Ops: a morning session from real runs — a run on the road (stops recorded, late against plan by its
# ETA to the next stop), children boarded by QR / not at the stop / Bus Not Required from the parent / waiting, what needs
# attention, a run in detail (crew, how children boarded, the log), GPS lost, and the afternoon not started yet.
RSpec.describe "School Bus Live Ops" do
  let(:company) { create(:company) }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      bus = create(:vehicle, plate: "PD6604E", seats: 40)
      bus.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      bus2 = create(:vehicle, plate: "PD1125G", seats: 23)
      ba = Attendant.create!(name: "Mdm Rosnah", phone: "+6591112233")
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", lat: 1.3138, lng: 103.9283)
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
      %w[S-1 S-2 S-3 S-4 S-5].each_with_index do |rid, i|
        school.riders.create!(rid:, name: "Child #{i + 1}", grade: "P#{i + 1}", postal: "46012#{i}", am: true, pm: true, source: "manual")
      end
      am = school.plans.create!(name: "Term 4 AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
      r1 = am.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20", bus_type: "LARGE_40", seats: 40, attendant: ba)
      s1 = r1.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "06:30", lat: 1.3305, lng: 103.9373)
      s2 = r1.stops.create!(position: 1, name: "Blk 32 Siglap", scheduled_time: "06:45", lat: 1.3136, lng: 103.9247)
      [ [ s1, "S-1" ], [ s1, "S-2" ], [ s1, "S-4" ], [ s2, "S-3" ] ].each { |s, rid| SchoolRouteRider.create!(school_route: r1, stop: s, rid:) }
      r1.vehicle_changes.create!(vehicle: bus, effective_from: Date.new(2026, 10, 1))
      r2 = am.routes.create!(number: 2, label: "AM 2", start_time: "06:40", end_time: "07:15", bus_type: "MEDIUM_23", seats: 23)
      t1 = r2.stops.create!(position: 0, name: "Kembangan MRT", scheduled_time: "06:40", lat: 1.3210, lng: 103.9129)
      SchoolRouteRider.create!(school_route: r2, stop: t1, rid: "S-5")
      r2.vehicle_changes.create!(vehicle: bus2, effective_from: Date.new(2026, 10, 1))
      pm = school.plans.create!(name: "Term 4 PM", session: "pm", effective_from: Date.new(2026, 10, 1), in_use: true)
      p1 = pm.routes.create!(number: 1, label: "PM 1", start_time: "13:40", end_time: "14:30")
      p1.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "14:10")
      school.rider_absences.create!(rid: "S-4", date: Date.new(2026, 11, 3), trip: "both", reason: "sick", note: "Fever", reported_by: "Parent")
      { school:, r1:, r2:, bus:, bus2: }
    end
  end
  let(:school) { f[:school] }

  before do
    travel_to Time.zone.local(2026, 11, 3, 5, 0)
    within_tenant(company) { Occurrences::Sync.call(routes: SchoolRoute.all.to_a) }
    travel_to Time.zone.local(2026, 11, 3, 6, 50)
    within_tenant(company) do
      day = Date.new(2026, 11, 3)
      occ = f[:r1].occurrences.find_by!(date: day)
      occ.update_columns(started_at: Time.zone.local(2026, 11, 3, 6, 28))
      occ.stop_events.create!(position: 0, stop_name: "Blk 101 Bedok North", arrived_at: Time.zone.local(2026, 11, 3, 6, 31),
                              departed_at: Time.zone.local(2026, 11, 3, 6, 34), boarded: 1)
      # Still 2 km from the second stop at 06:49 (planned 06:45): late
      VehicleLivePosition.create!(vehicle: f[:bus], lat: 1.3305, lng: 103.9373, speed_kmh: 30, heading: 200, recorded_at: Time.zone.local(2026, 11, 3, 6, 49, 30))
      OccurrencePassenger.create!(occurrence: occ, passenger_key: "S-1", state: "boarded", boarded_at: Time.zone.local(2026, 11, 3, 6, 32),
                                  board_method: "qr", board_lat: 1.33052, board_lng: 103.93731, marked_by: "Mdm Rosnah")
      OccurrencePassenger.create!(occurrence: occ, passenger_key: "S-2", state: "not_boarded", marked_by: "Mdm Rosnah")
      # AM 2 started but its bus last reported 10 min ago
      o2 = f[:r2].occurrences.find_by!(date: day)
      o2.update_columns(started_at: Time.zone.local(2026, 11, 3, 6, 38))
      VehicleLivePosition.create!(vehicle: f[:bus2], lat: 1.3210, lng: 103.9129, recorded_at: Time.zone.local(2026, 11, 3, 6, 40))
    end
    sign_in_as(create(:user, company:))
  end

  it "shows the morning session: KPIs, what needs attention and a row per run" do
    get api_v1_school_live_path(school), params: { date: "2026-11-03" }
    d = json[:data]
    expect(d[:session]).to eq("am")
    expect(d[:sessions].pluck(:value, :runs)).to eq([ [ "am", 2 ], [ "pm", 1 ] ])
    expect(d[:kpis]).to include(points: 5, points_done: 1, buses: { on_road: 2, arrived: 0, not_started: 0, total: 2 })
    expect(d[:kpis][:riders]).to include(on_board: 1, waiting: 2, no_show: 1, not_required: 1, absent: 2, total: 5)
    expect(d[:attention].map { [ it[:route], it[:kind], it[:severity] ] }).to eq([ [ "AM 1", "late", 4 ], [ "AM 2", "gps_lost", 4 ], [ "AM 1", "no_show", 2 ] ])
    expect(d[:attention].last).to include(title: "Student not at stop", rider: { rid: "S-2", name: "Child 2" }, stop: "Blk 101 Bedok North", marked_by: "Mdm Rosnah")
    expect(d[:filters]).to eq(all: 2, road: 2, late: 2, done: 0)

    a1 = d[:rows].find { it[:label] == "AM 1" }
    expect(a1).to include(plate: "PD6604E", driver: { name: "Kumar", phone: "+6591234567" }, points: 3, points_done: 1)
    expect(a1[:status]).to include(key: "late", tone: "danger")
    expect(a1[:next_stop]).to include(name: "Blk 32 Siglap", at_stop: false)
    expect(a1[:line]).to eq([ [ 1.3305, 103.9373 ], [ 1.3136, 103.9247 ], [ 1.3138, 103.9283 ] ])
    expect(a1[:position]).to include(lat: 1.3305, lng: 103.9373)
    expect(d[:rows].find { it[:label] == "AM 2" }[:status]).to include(key: "gps_lost")

    get api_v1_school_live_path(school), params: { date: "2026-11-03", session: "pm", filter: "done" }
    expect(json[:data]).to include(session: "pm", rows: [])
    expect(json.dig(:data, :kpis, :buses)).to include(not_started: 1)
  end

  it "opens a run: crew, how children boarded, the log and each stop with its children" do
    id = within_tenant(company) { f[:r1].occurrences.find_by!(date: Date.new(2026, 11, 3)).id }
    get api_v1_school_live_run_path(school, id)
    d = json[:data]
    expect(d).to include(label: "AM 1", session: "am", bus: { plate: "PD6604E", type: "40-seater", bus_type: "LARGE_40", bus_type_label: "40-seater", seats: 40, operator: "Own fleet" }, on_board: 1)
    expect(d[:alert]).to include(kind: "late", tone: "danger")
    expect(d[:methods]).to eq(tick: 0, qr: 1, card: 0, palm: 0)
    expect(d[:crew]).to eq([ { role: "Driver", name: "Kumar", phone: "+6591234567", photo: nil }, { role: "Bus Attendant", name: "Mdm Rosnah", phone: "+6591112233", photo: nil } ])
    expect(d[:log].pluck(:text)).to eq([ "1 student boarded at Blk 101 Bedok North", "Child 2 not at stop. Marked by Mdm Rosnah",
                                         "Arrived at Blk 101 Bedok North", "Trip started" ])
    first, second = d[:stops]
    expect(first).to include(number: 1, state: "done", late_minutes: 1)
    expect(first[:riders].map { [ it[:rid], it[:status] ] }).to eq([ %w[S-1 on_board], %w[S-2 no_show], %w[S-4 not_required] ])
    expect(first[:riders].first).to include(board_method: "qr", board: hash_including(distance_m: 2))
    expect(first[:riders].last).to include(marked_by: "Parent", reason: "Unwell. Fever")
    expect(second).to include(state: "todo", riders: [ hash_including(rid: "S-3", status: "waiting") ])
    expect(second[:expected_at]).to be > "2026-11-03T06:45:00.000+08:00"
  end

  it "counts a child nobody ticked as on board once the bus left the stop, then at school once the run is done" do
    day = Date.new(2026, 11, 3)
    within_tenant(company) { f[:r1].occurrences.find_by!(date: day).passenger_marks.where(passenger_key: "S-1").delete_all }
    id = within_tenant(company) { f[:r1].occurrences.find_by!(date: day).id }
    get api_v1_school_live_run_path(school, id)
    expect(json.dig(:data, :stops, 0, :riders).find { it[:rid] == "S-1" }).to include(status: "on_board", marked_by: nil)
    expect(json.dig(:data, :stops, 1, :riders).first).to include(rid: "S-3", status: "waiting") # its stop is not left yet

    within_tenant(company) { TripOccurrence.find(id).update_columns(ended_at: Time.zone.local(2026, 11, 3, 7, 21)) }
    get api_v1_school_live_run_path(school, id)
    expect(json.dig(:data, :stops).flat_map { it[:riders] }.pluck(:status)).to eq(%w[at_school no_show not_required at_school])
    expect(json.dig(:data, :counts)).to include(at_school: 2, no_show: 1, not_required: 1, waiting: 0)
  end

  it "drops an afternoon child off at the stop the bus has left" do
    day = Date.new(2026, 11, 3)
    within_tenant(company) do
      p1 = SchoolRoute.joins(:plan).find_by!(school_plans: { session: "pm" }, label: "PM 1")
      SchoolRouteRider.create!(school_route: p1, stop: p1.stops.first, rid: "S-1")
      occ = p1.occurrences.find_by!(date: day)
      occ.update_columns(started_at: Time.zone.local(2026, 11, 3, 6, 0))
      occ.stop_events.create!(position: 0, stop_name: "Blk 101 Bedok North", arrived_at: Time.zone.local(2026, 11, 3, 6, 1), departed_at: Time.zone.local(2026, 11, 3, 6, 2))
      @pm_id = occ.id
    end
    get api_v1_school_live_run_path(school, @pm_id)
    expect(json.dig(:data, :stops, 0, :riders)).to contain_exactly(hash_including(rid: "S-1", status: "dropped_off"))
  end

  it "fills the bus type from the seats, adds the crew's photos and the stop address from its PUDO point" do
    day = Date.new(2026, 11, 3)
    within_tenant(company) do
      f[:r2].update_columns(bus_type: nil, seats: nil)
      stop = Stop.create!(name: "Kembangan MRT", code: "BDSZ05-0001", subzone_code: "BDSZ05")
      point = stop.all_points.create!(suffix: "A", lat: 1.3210, lng: 103.9129, sizes: %w[L], description: "Bus stop opposite Kembangan MRT")
      f[:r2].stops.first.update!(stop_point: point)
      f[:r1].attendant.update!(photo: fixture_file_upload("photo.png", "image/png"))
      f[:bus].driver_schedules.first.driver.update!(photo: fixture_file_upload("photo.png", "image/png"))
    end
    id2 = within_tenant(company) { f[:r2].occurrences.find_by!(date: day).id }
    get api_v1_school_live_run_path(school, id2)
    expect(json.dig(:data, :bus)).to include(type: "23-seater", bus_type: "MEDIUM_23", bus_type_label: "23-seater", seats: 23) # the bus's 23 seats
    expect(json.dig(:data, :stops, 0)).to include(name: "Kembangan MRT", address: "Bus stop opposite Kembangan MRT")

    id1 = within_tenant(company) { f[:r1].occurrences.find_by!(date: day).id }
    get api_v1_school_live_run_path(school, id1)
    expect(json.dig(:data, :crew).pluck(:photo)).to all(start_with("/api/v1/downloads/"))
    expect(json.dig(:data, :stops, 0)).to include(address: nil)
  end

  it "writes sample attendance for the runs that have started (seed / live_map:simulate)" do
    within_tenant(company) { SchoolLive::Simulate.call }
    rows = within_tenant(company) { OccurrencePassenger.order(:passenger_key).pluck(:passenger_key, :state, :board_method) }
    expect(rows.map(&:first)).to eq(%w[S-1 S-2]) # S-4 Bus Not Required, S-3's stop not left yet, AM 2 has no stop left
    expect(rows.map { it[1] }).to all(eq("boarded"))
    within_tenant(company) { SchoolLive::Simulate.call }
    expect(within_tenant(company) { OccurrencePassenger.count }).to eq(2)
  end

  it "shows a School Bus run on the Live Map with the school and the children at each stop" do
    within_tenant(company) { school.riders.find_by!(rid: "S-1").update!(address: "101 Bedok North Ave 4") }
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
    get api_v1_live_map_vehicle_path(f[:bus])
    run = json.dig(:data, :run)
    expect(run).to include(school: "St. Stephen's School", kind_name: "School Route")
    first = run[:stops].find { it[:name] == "Blk 101 Bedok North" }
    expect(first[:students].map { it.slice(:key, :class_name, :status) })
      .to eq([ { key: "S-1", class_name: "P1", status: "boarded" }, { key: "S-2", class_name: "P2", status: "not_boarded" },
               { key: "S-4", class_name: "P4", status: "not_boarding" } ])
    expect(first[:students].first).to include(name: "Child 1", address: "101 Bedok North Ave 4")
  end
end
