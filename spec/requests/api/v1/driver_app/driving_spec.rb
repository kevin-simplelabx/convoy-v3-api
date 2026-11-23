require "rails_helper"

# Convoy Driver app › On Route: start (not too early, one trip at a time), arrive and leave with the count or the names
# first, skip a point, complete with feedback, a School Bus run (attendance, QR, leave early, Edit Route, alight all at
# the school), Force End Trip and Skip Trip as Trip History shows them, an action sent twice done once, and a run the
# main contractor wants in its own app (stay, or continue there and confirm completion).
RSpec.describe "Driver app driving" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      bus = create(:vehicle, plate: "PD3318K", seats: 23)
      bus.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      { kumar:, bus:, client: create(:client, name: "Google"), type: create(:vehicle_type) }
    end
  end
  let(:day) { Date.new(2026, 11, 3) }

  before { travel_to Time.zone.local(2026, 11, 2, 6, 0) }

  def create_trip(start_time: "08:00", end_time: "09:00", client: f[:client], **extra)
    sign_in_as(create(:user, :admin, company:))
    post api_v1_trips_path, params: { trip: {
      **extra, kind: "ad_hoc", client_id: client.id, starts_on: day.iso8601, start_time:, end_time:, price: 100, trip_value: 1, pax: 12,
      stops_attributes: [ { position: 0, name: "Jurong East MRT", use: "pu" }, { position: 1, name: "Clementi Ave 6", use: "via" },
                          { position: 2, name: "Mapletree Business City", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ],
      vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:bus].id } ]
    } }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    within_tenant(company) { TripOccurrence.find_by!(trip_id: json.dig(:data, :id)) }
  end

  def act(token, occ, action, **params)
    params = { client_id: SecureRandom.uuid, at: Time.current.iso8601 }.merge(params)
    if action == :route then patch route_api_v1_driver_app_run_path(occ.id), params:, headers: as(token), as: :json
    else post public_send(:"#{action}_api_v1_driver_app_run_path", occ.id), params:, headers: as(token), as: :json
    end
    json
  end

  def error = json.dig(:error, :code)

  it "drives a counted run: start, count, leave, complete with feedback; the same action twice is done once" do
    within_tenant(company) { Trip.find(create_trip.trip_id).update_columns(head_count: true) }
    occ = within_tenant(company) { TripOccurrence.find_by!(date: day) }
    token = driver_token("91234567")

    travel_to Time.zone.local(2026, 11, 3, 6, 30)
    act(token, occ, :start)
    expect([ error, json.dig(:error, :message) ]).to eq([ "too_early", "You can start this trip from 07:00" ])
    act(token, occ, :arrive, position: 0)
    expect(error).to eq("not_started")
    act(token, occ, :count, position: 0, boarded: 7, alighted: 0)
    expect(error).to eq("not_started")
    expect(within_tenant(company) { occ.stop_events.reload }).to be_empty

    travel_to Time.zone.local(2026, 11, 3, 7, 30)
    id = SecureRandom.uuid
    act(token, occ, :start, client_id: id)
    expect(json[:data]).to include(status: "on_the_way", seen: true)
    expect(json[:meta]).to eq(replayed: false)
    act(token, occ, :start, client_id: id)
    expect(json[:meta]).to eq(replayed: true)

    travel_to Time.zone.local(2026, 11, 3, 7, 58)
    act(token, occ, :arrive, position: 1)
    expect(json.dig(:error, :message)).to eq("Clementi Ave 6 is a waypoint: drive through it")
    act(token, occ, :arrive, position: 0)
    act(token, occ, :leave, position: 0)
    expect([ error, json.dig(:error, :message) ]).to eq([ "count_needed", "Count the passengers at Jurong East MRT first" ])
    act(token, occ, :count, position: 0, boarded: 7, alighted: 0)
    act(token, occ, :leave, position: 0)
    expect(json[:data]).to include(status: "started")
    expect(json.dig(:data, :points, 0, :record)).to include(boarded: 7, alighted: 0, on_board: 7, left_early: nil, skip_reason: nil, departed_at: be_present)
    expect(json[:data]).to include(driver_end: nil, driver_feedback: nil)

    travel_to Time.zone.local(2026, 11, 3, 8, 40)
    act(token, occ, :arrive, position: 2)
    act(token, occ, :complete, feedback: "Clementi pick-up B is blocked by roadworks")
    expect(json[:data]).to include(status: "ended", ended_at: be_present)
    expect(json.dig(:data, :points, 2, :record)).to include(alighted: 7, on_board: 0)
    expect(json.dig(:data, :driver_end)).to include(kind: "completed", reason: nil, on_board: 0, at: json.dig(:data, :ended_at))
    expect(json.dig(:data, :driver_feedback)).to include(note: "Clementi pick-up B is blocked by roadworks", at: be_present)
    act(token, occ, :arrive, position: 0)
    expect(error).to eq("ended")

    within_tenant(company) do
      occ.reload
      expect(occ).to have_attributes(driver_end: "completed", started_at: Time.zone.local(2026, 11, 3, 7, 30), max_delay_minutes: -2)
      expect(occ.stop_events.order(:position).pluck(:position, :on_board, :source)).to eq([ [ 0, 7, "driver_app" ], [ 2, 0, "driver_app" ] ])
      expect(occ.driver_report).to have_attributes(note: "Clementi pick-up B is blocked by roadworks", driver_name: "Kumar")
      expect(DriverAppAction.where(occurrence_id: occ.id).pluck(:kind)).to eq(%w[start arrive count leave arrive complete])
    end

    travel_to Time.zone.local(2026, 11, 4, 9, 0)
    OccurrenceCompleteJob.perform_now
    sign_in_as(create(:user, :admin, company:))
    get api_v1_trip_history_run_path(occ.id)
    expect(json[:data]).to include(on_time: "on_time")
  end

  it "ends a run the job completed before the driver started it, and keeps one on the road drivable until the driver ends it" do
    idle = create_trip
    driven = within_tenant(company) { TripOccurrence.find_by!(trip_id: create_trip(start_time: "10:00", end_time: "11:00").trip_id) }
    token = driver_token("91234567")

    travel_to Time.zone.local(2026, 11, 3, 9, 45)
    act(token, driven, :start)
    travel_to Time.zone.local(2026, 11, 3, 11, 30)
    OccurrenceCompleteJob.perform_now
    expect([ idle.reload.status, driven.reload.status ]).to eq(%w[completed completed])

    get api_v1_driver_app_runs_path, params: { date: day.iso8601 }, headers: as(token)
    expect(json[:data].map { [ it[:id], it[:status], it[:started_at].present? ] }).to eq([ [ idle.id, "ended", false ], [ driven.id, "on_the_way", true ] ])
    get on_going_api_v1_driver_app_runs_path, headers: as(token)
    expect(json.dig(:data, :id)).to eq(driven.id)

    %i[start arrive attendance skip force_end].each do |action|
      act(token, idle, action, position: 0, marks: [ { id: "x", state: "boarded" } ], reason: "Other", called_operations: true)
      expect([ action, response.status, error ]).to eq([ action, 422, "ended" ])
    end
    expect(within_tenant(company) { DriverAppAction.where(occurrence_id: idle.id).count }).to eq(0)

    act(token, driven, :arrive, position: 0)
    act(token, driven, :leave, position: 0, boarded: 3)
    expect(json[:data]).to include(status: "started")
    act(token, driven, :complete)
    expect(json[:data]).to include(status: "ended", ended_at: be_present)
    get on_going_api_v1_driver_app_runs_path, headers: as(token)
    expect(json[:data]).to be_nil
  end

  it "keeps one trip on the road, force ends with a reason, and skips a trip as Trip History shows" do
    early = create_trip
    late = within_tenant(company) do
      trip = create(:trip, client: f[:client], start_time: "10:00", end_time: "11:00", starts_on: day)
      TripOccurrence.create!(trip:, client: trip.client, date: day, start_time: 600, end_time: 660, starts_at: day.in_time_zone.change(hour: 10),
                             ends_at: day.in_time_zone.change(hour: 11), kind: "ad_hoc", trip_label: "TID000099", vehicle: f[:bus], driver: f[:kumar], run_key: "x")
    end
    token = driver_token("91234567")
    travel_to Time.zone.local(2026, 11, 3, 9, 15)
    act(token, early, :start)
    act(token, late, :start)
    expect([ error, json.dig(:error, :details) ]).to eq([ "busy", { run_id: early.id } ])

    act(token, early, :arrive, position: 0)
    act(token, early, :leave, position: 0)
    act(token, early, :force_end, reason: "Accident")
    expect(error).to eq("call_operations")
    act(token, early, :force_end, reason: "Flat tyre", called_operations: true)
    expect(json.dig(:error, :details, :reason)).to eq([ "is not on the list" ])
    act(token, early, :force_end, reason: "Vehicle breakdown", called_operations: true)
    expect(json[:data]).to include(status: "ended")
    expect(json.dig(:data, :points, 2, :record)).to include(skipped: true, skip_reason: "Trip force ended", skipped_at: be_present)
    expect(json.dig(:data, :driver_end)).to include(kind: "forced", reason: "Vehicle breakdown", on_board: 0, at: be_present)
    expect(json.dig(:data, :driver_feedback, :note)).to eq("Force ended: Vehicle breakdown")

    act(token, late, :skip, reason: "Traffic Congestion")
    expect(json[:data]).to include(status: "skipped", status_label: "Skipped", ended_at: nil)
    expect(json.dig(:data, :driver_end)).to include(kind: "skipped", reason: "Traffic Congestion", at: be_present)
    get api_v1_driver_app_runs_path, params: { date: day.iso8601 }, headers: as(token)
    expect(json[:data].find { it[:id] == late.id }.dig(:driver_end, :kind)).to eq("skipped")

    travel_to Time.zone.local(2026, 11, 4, 9, 0)
    sign_in_as(create(:user, :admin, company:))
    get api_v1_trip_history_path, params: { from: day.iso8601, to: day.iso8601 }
    expect(json[:data].map { [ it[:id], it[:outcome] ] }).to contain_exactly([ early.id, "completed" ], [ late.id, "skipped_by_driver" ])
    get api_v1_trip_history_run_path(early.id)
    expect(json[:data]).to include(driver_end: { kind: "forced", reason: "Vehicle breakdown", on_board: 0 })
    expect(json.dig(:data, :stops).map { it[:skip_reason] }).to eq([ nil, nil, "Trip force ended" ])
  end

  it "moves the run's lock_version on when the driver force ends or skips it, so a drawer opened before gets 409" do
    early = create_trip
    late = create_trip(start_time: "10:00", end_time: "11:00")
    token = driver_token("91234567")
    travel_to Time.zone.local(2026, 11, 3, 9, 15)
    act(token, early, :start)
    act(token, early, :arrive, position: 0)
    act(token, early, :leave, position: 0)
    seen = { early => early.reload.lock_version, late => late.reload.lock_version }

    act(token, early, :force_end, reason: "Vehicle breakdown", called_operations: true)
    act(token, late, :skip, reason: "Traffic Congestion")

    sign_in_as(create(:user, :admin, company:))
    seen.each do |occ, version|
      expect(occ.reload.lock_version).to eq(version + 1)
      patch (occ == late ? restore_api_v1_occurrence_path(occ.id) : cancel_api_v1_occurrence_path(occ.id)), params: { lock_version: version }, as: :json
      expect(response).to have_http_status(:conflict)
    end
    patch restore_api_v1_occurrence_path(late.id), params: { lock_version: seen[late] + 1 }, as: :json
    expect(response).to have_http_status(:ok)
    expect(late.reload).to have_attributes(driver_end: nil, driver_end_reason: nil) # restored: no longer skipped by the driver
  end

  describe "a School Bus run" do
    let!(:route) do
      within_tenant(company) do
        school = School.create!(name: "St. Stephen's School", short_name: "SSS", lat: 1.3138, lng: 103.9283)
        year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
        year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
        %w[S-1 S-2 S-3 S-4].each_with_index { |rid, i| school.riders.create!(rid:, name: "Child #{i + 1}", postal: "46012#{i}", am: true, pm: true, source: "manual") }
        am = school.plans.create!(name: "Term 4 AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
        r = am.routes.create!(number: 1, label: "AM 1", start_time: "06:30", end_time: "07:20", bus_type: "LARGE_40", seats: 40)
        s1 = r.stops.create!(position: 0, name: "Blk 101 Bedok North", scheduled_time: "06:30")
        s2 = r.stops.create!(position: 1, name: "Blk 32 Siglap", scheduled_time: "06:45")
        s3 = r.stops.create!(position: 2, name: "Blk 9 Kembangan", scheduled_time: "06:55")
        [ [ s1, "S-1" ], [ s1, "S-2" ], [ s2, "S-3" ], [ s3, "S-4" ] ].each { |s, rid| SchoolRouteRider.create!(school_route: r, stop: s, rid:) }
        r.vehicle_changes.create!(vehicle: f[:bus], effective_from: Date.new(2026, 10, 1))
        school.rider_absences.create!(rid: "S-2", date: day, trip: "both", reason: "sick", reported_by: "Parent")
        Occurrences::Sync.call(routes: [ r ])
        r
      end
    end

    it "takes attendance before leaving, leaves early on purpose, follows Edit Route and alights everyone at the school" do
      occ = within_tenant(company) { route.occurrences.find_by!(date: day) }
      token = driver_token("91234567")
      travel_to Time.zone.local(2026, 11, 3, 6, 0)
      act(token, occ, :route, skip: [ 2 ], not_boarding: [ "S-4" ])
      expect(json.dig(:data, :passengers).to_h { [ it[:id], it[:state] ] }).to eq("S-1" => "expected", "S-2" => "bus_not_required", "S-3" => "expected", "S-4" => "not_boarding")
      expect(json.dig(:data, :points, 2, :record)).to include(skipped: true, skipped_at: nil) # not passed yet
      expect(json.dig(:data, :before_you_go, :not_riding).pluck(:id)).to eq(%w[S-2 S-4])
      expect(json.dig(:data, :before_you_go, :skipped_points)).to eq([ { position: 2, name: "Blk 9 Kembangan" } ])

      act(token, occ, :start)
      act(token, occ, :arrive, position: 0)
      act(token, occ, :leave, position: 0)
      expect([ error, json.dig(:error, :details) ]).to eq([ "attendance_needed", { missing: 1, names: [ "Child 1" ] } ])
      pass = DriverApp::RiderPass.code(company.id, "S-1")
      act(token, occ, :attendance, marks: [ { id: "S-1", state: "boarded", method: "qr", lat: 1.33, lng: 103.93 } ])
      expect(json.dig(:data, :passengers, 0)).to include(state: "boarded", qr_code: pass)
      act(token, occ, :attendance, marks: [ { id: "S-9", state: "boarded" } ])
      expect([ error, json.dig(:error, :message) ]).to eq([ "not_on_trip", "S-9 is not on this trip" ])
      act(token, occ, :leave, position: 0)
      expect(json.dig(:data, :points, 0, :record)).to include(boarded: 1)

      act(token, occ, :arrive, position: 1)
      act(token, occ, :leave, position: 1, force: true)
      expect(json.dig(:data, :points, 1, :record)).to include(left_early: { missing: 1, until: "06:47" }, on_board: 1) # Blk 32 Siglap 06:45 + 2 min grace
      act(token, occ, :skip_stop, position: 2, auto: true)
      expect(json.dig(:data, :points, 2, :record)).to include(skipped: true, skipped_at: be_present, skip_reason: "Skipped by the driver before the trip")
      act(token, occ, :arrive, position: 3)
      act(token, occ, :complete)
      expect(json.dig(:data, :passengers).to_h { [ it[:id], it[:state] ] }).to include("S-1" => "alighted", "S-3" => "expected")

      within_tenant(company) do
        events = occ.stop_events.reload.order(:position).pluck(:position, :boarded, :alighted, :on_board, :left_early_missing, :skipped_by)
        expect(events).to eq([ [ 0, 1, 0, 1, nil, nil ], [ 1, 0, 0, 1, 1, nil ], [ 2, nil, nil, 1, nil, "plan" ], [ 3, nil, 1, 0, nil, nil ] ])
        expect(OccurrencePassenger.find_by(passenger_key: "S-1")).to have_attributes(board_method: "qr", board_lat: 1.33, marked_by: "Kumar")
      end

      sign_in_as(create(:user, :admin, company:))
      get api_v1_school_live_path(route.plan.school), params: { date: day.iso8601 }
      expect(json.dig(:data, :kpis, :riders)).to include(at_school: 2, not_required: 2, waiting: 0) # S-3 was never ticked: at school as the run is done

      travel_to Time.zone.local(2026, 11, 4, 9, 0)
      OccurrenceCompleteJob.perform_now
      get api_v1_trip_history_run_path(occ.id)
      list = json.dig(:data, :passengers)
      expect(list[:list]).to eq("Term 4 AM")
      expect(list[:stops].map { [ it[:name], it[:time], it[:students].map { |k| [ k[:key], k[:status] ] } ] }).to eq([
        [ "Blk 101 Bedok North", "06:30", [ %w[S-1 alighted], %w[S-2 bus_not_required] ] ],
        [ "Blk 32 Siglap", "06:45", [ %w[S-3 expected] ] ],
        [ "Blk 9 Kembangan", "06:55", [ %w[S-4 not_boarding] ] ]
      ])
      expect(list.dig(:stops, 0, :students, 0)).to include(name: "Child 1", board_method: "qr", by: "Kumar", boarded_at: be_present, alighted_at: be_present)
      expect(list.dig(:stops, 0, :students, 1)).to include(reason: "Unwell")
      expect(json[:data]).to include(on_time: "on_time")
    end
  end

  it "skips a point with a reason, once, and not after the driver has left it or on a trip that has not started" do
    occ = create_trip
    token = driver_token("91234567")
    act(token, occ, :skip_stop, position: 0)
    expect(error).to eq("not_started")

    travel_to Time.zone.local(2026, 11, 3, 7, 30)
    act(token, occ, :start)
    act(token, occ, :skip_stop, position: 0)
    expect(json.dig(:error, :details, :reason)).to eq([ "can't be blank" ])
    act(token, occ, :skip_stop, position: 9, reason: "Passenger not at the point")
    expect(json.dig(:error, :details, :position)).to eq([ "is not a point of this trip" ])

    id = SecureRandom.uuid
    act(token, occ, :skip_stop, position: 0, reason: "Passenger not at the point", client_id: id)
    expect(json.dig(:data, :points, 0, :record)).to include(skipped: true, skipped_at: Time.current.iso8601(3))
    expect(json[:meta]).to eq(replayed: false)
    act(token, occ, :skip_stop, position: 0, reason: "Passenger not at the point", client_id: id)
    expect(json[:meta]).to eq(replayed: true)
    within_tenant(company) do
      expect(occ.stop_events.find_by!(position: 0)).to have_attributes(skipped: true, skip_reason: "Passenger not at the point", skipped_by: "driver")
      expect(DriverAppAction.where(occurrence_id: occ.id, kind: "skip_stop").count).to eq(1)
    end

    act(token, occ, :arrive, position: 2)
    act(token, occ, :leave, position: 2)
    act(token, occ, :skip_stop, position: 2, reason: "Passenger not at the point")
    expect(json.dig(:error, :message)).to eq("Mapletree Business City was already reached")
  end

  it "keeps a run out of reach of another driver's skip, and of a token that is not a driver's" do
    occ = create_trip
    within_tenant(company) { create(:driver, name: "Other", phone: "+6598887777") }
    travel_to Time.zone.local(2026, 11, 3, 7, 30)
    act(driver_token("91234567"), occ, :start)

    act(driver_token("98887777"), occ, :skip_stop, position: 0, reason: "Passenger not at the point")
    expect(response).to have_http_status(:not_found)
    post skip_stop_api_v1_driver_app_run_path(occ.id), params: { position: 0, reason: "Passenger not at the point" }, headers: as(app_token(mobile: "9188 2045")), as: :json
    expect(response).to have_http_status(:unauthorized)
    integration_session.bearer_token = nil
    post skip_stop_api_v1_driver_app_run_path(occ.id), params: { position: 0, reason: "x" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "records the main contractor's app choice after Start and completes a run driven in that app, as Ops Control and Trip History show" do
    eastern = within_tenant(company) { create(:client, name: "Eastern Coaches", kind: :transport_company) }
    sub = create_trip(client: eastern, require_contractor_app: true, contractor_contact_name: "Mr Goh")
    plain = create_trip(start_time: "10:00", end_time: "11:00")
    token = driver_token("91234567")

    travel_to Time.zone.local(2026, 11, 3, 7, 30)
    act(token, plain, :app_choice, choice: "stay")
    expect([ response.status, error ]).to eq([ 422, "not_required" ])
    act(token, sub, :app_choice, choice: "stay")
    expect(error).to eq("not_started")

    act(token, sub, :start)
    expect(json.dig(:data, :contractor)).to eq(name: "Eastern Coaches", requires_app: true, choice: nil, chosen_at: nil)
    act(token, sub, :complete, on_contractor_app: true)
    expect([ error, json.dig(:error, :message) ]).to eq([ "choose_contractor_first", "Choose Continue on Eastern Coaches first" ])
    act(token, sub, :app_choice, choice: "both")
    expect(json.dig(:error, :details, :choice)).to eq([ "is not on the list" ])
    act(token, sub, :app_choice, choice: "stay")
    expect(json.dig(:data, :contractor)).to include(choice: "stay", chosen_at: be_present)

    travel_to Time.zone.local(2026, 11, 3, 7, 35)
    id = SecureRandom.uuid
    expect { act(token, sub, :app_choice, client_id: id, choice: "contractor") }
      .to have_broadcasted_to("run:#{sub.id}").with(type: "run_changed", run_id: sub.id)
    expect([ json.dig(:data, :contractor, :choice), json[:meta] ]).to eq([ "contractor", { replayed: false } ])
    act(token, sub, :app_choice, client_id: id, choice: "contractor")
    expect(json[:meta]).to eq(replayed: true)
    get api_v1_driver_app_runs_path, params: { date: day.iso8601 }, headers: as(token)
    expect(json[:data].to_h { [ it[:id], it.dig(:contractor, :choice) ] }).to eq(sub.id => "contractor", plain.id => nil)

    # Past the first pick-up with no stop and no GPS: nothing to alert on, the run is tracked in the contractor's app.
    travel_to Time.zone.local(2026, 11, 3, 8, 20)
    sign_in_as(create(:user, :admin, company:))
    get api_v1_ops_control_path, params: { tab: "all" }
    row = json.dig(:data, :rows).find { it[:id] == sub.id }
    expect([ row[:gps][:status], row[:alerts], row[:state] ]).to eq([ "on_contractor_app", [], "on_the_way" ])

    travel_to Time.zone.local(2026, 11, 3, 9, 5)
    act(token, sub, :complete, on_contractor_app: true)
    expect(json[:data]).to include(status: "ended", ended_at: be_present)
    expect(json.dig(:data, :driver_end)).to include(kind: "completed", on_board: nil)
    expect(json.dig(:data, :driver_feedback, :note)).to eq("Completed on Eastern Coaches. Stops and counts recorded there.")
    expect(json.dig(:data, :points).map { it[:record] }).to all(be_nil)

    travel_to Time.zone.local(2026, 11, 4, 9, 0)
    OccurrenceCompleteJob.perform_now
    get api_v1_trip_history_path, params: { from: day.iso8601, to: day.iso8601 }
    expect(json[:data].find { it[:id] == sub.id }[:outcome]).to eq("completed")
    get api_v1_trip_history_run_path(sub.id)
    expect(json[:data]).to include(driver_end: { kind: "completed", reason: nil, on_board: nil },
                                   contractor_app: { name: "Eastern Coaches", choice: "contractor", chosen_at: be_present })
    get api_v1_trip_history_run_path(plain.id)
    expect(json.dig(:data, :contractor_app)).to be_nil
  end
end
