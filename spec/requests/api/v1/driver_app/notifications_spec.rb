require "rails_helper"

# Convoy Driver app › the bell: lines when a trip today or tomorrow is given to the driver, taken by a replacement,
# moved, cancelled and restored by the office, a bus to take over, and notices from the office — Open ones read when
# opened, Acknowledge ones unread until acknowledged.
RSpec.describe "Driver app notifications" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let!(:f) do
    within_tenant(company) do
      kumar = create(:driver, name: "Kumar", phone: "+6591234567")
      siti = create(:driver, name: "Siti", phone: "+6598765432")
      a = create(:vehicle, plate: "PD3318K")
      b = create(:vehicle, plate: "PD4472H")
      a.driver_schedules.create!(driver: kumar, starts_on: Date.new(2026, 10, 1))
      b.driver_schedules.create!(driver: siti, starts_on: Date.new(2026, 10, 1))
      { kumar:, siti:, a:, b:, client: create(:client, name: "Google"), type: create(:vehicle_type) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 3, 6, 0)
    sign_in_as(create(:user, :admin, company:))
  end

  def bell(token)
    get api_v1_driver_app_notifications_path, headers: as(token)
    json
  end

  def lines(token) = bell(token)[:data].map { [ it[:kind], it[:body] ] }

  it "tells the driver about trips given, taken, moved, cancelled and restored, and a bus to take over" do
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", client_id: f[:client].id, title: "Google Shuttle", starts_on: "2026-11-03", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00", price: 100, trip_value: 1,
      stops_attributes: [ { position: 0, name: "Jurong East", use: "pu" }, { position: 1, name: "MBC", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:a].id } ]
    } }, as: :json
    trip_id = json.dig(:data, :id)
    run = ->(date) { within_tenant(company) { TripOccurrence.find_by!(trip_id:, date:) } }
    kumar = driver_token("91234567")
    expect(lines(kumar)).to eq([ [ "run_assigned", "Google Shuttle on tomorrow, 08:00. Open it to see the stops." ],
                                 [ "run_assigned", "Google Shuttle on today, 08:00. Open it to see the stops." ] ])
    expect(bell(kumar)[:meta]).to eq(unread: 2)

    integration_session.bearer_token = nil
    sign_in_as(create(:user, :admin, company:))
    post api_v1_replacements_path, params: { occurrence_id: run.(Date.new(2026, 11, 4)).id, replacement: { kind: "crew", vehicle_id: f[:b].id } }, as: :json
    within_tenant(company) { Occurrences::Edit.new(run.(Date.new(2026, 11, 3)), User.last).shift_today!("08:30") }
    within_tenant(company) { Occurrences::Edit.new(run.(Date.new(2026, 11, 3)), User.last).cancel! }
    within_tenant(company) { Occurrences::Edit.new(run.(Date.new(2026, 11, 3)).reload, User.last).restore! }
    within_tenant(company) { f[:b].driver_schedules.create!(driver: f[:kumar], starts_on: Date.new(2026, 11, 4), start_time: "06:30") }

    kumar = driver_token("91234567")
    expect(lines(kumar).first(4)).to eq([
      [ "vehicle_switch", "Switch to PD4472H from 06:30 tomorrow. Do the handover inspection before you take it." ],
      [ "run_changed", "Google Shuttle today, 08:30 is back on." ],
      [ "run_cancelled", "Google Shuttle today, 08:30 was cancelled." ],
      [ "run_changed", "Google Shuttle on today, 08:30 now starts at 08:30." ]
    ])
    expect(lines(kumar)).to include([ "run_unassigned", "Google Shuttle on tomorrow, 08:00 is now driven by another driver." ])
    siti = driver_token("98765432")
    expect(lines(siti)).to eq([ [ "run_assigned", "Google Shuttle on tomorrow, 08:00. Open it to see the stops." ] ])

    integration_session.bearer_token = nil
    sign_in_as(create(:user, :admin, company:))
    delete api_v1_trip_path(trip_id)
    siti = driver_token("98765432")
    expect(lines(siti).first).to eq([ "run_removed", "Google Shuttle on tomorrow, 08:00 is no longer planned." ])
  end

  # API-ISSUES #13: run.open = Trip Details would open now (worked out per request; the lines are never changed).
  it "says on each run line whether Trip Details opens: not once re-assigned or removed, again when the run comes back" do
    post api_v1_trips_path, params: { trip: {
      kind: "ad_hoc", client_id: f[:client].id, title: "Google Shuttle", starts_on: "2026-11-03", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
      start_time: "08:00", end_time: "09:00", price: 100, trip_value: 1,
      stops_attributes: [ { position: 0, name: "Jurong East", use: "pu" }, { position: 1, name: "MBC", use: "do" } ],
      vehicle_requirements_attributes: [ { vehicle_type_id: f[:type].id, count: 1 } ], vehicle_slots_attributes: [ { slot_no: 1, vehicle_id: f[:a].id } ]
    } }, as: :json
    trip_id = json.dig(:data, :id)
    today, tomorrow = within_tenant(company) { [ Date.new(2026, 11, 3), Date.new(2026, 11, 4) ].map { TripOccurrence.find_by!(trip_id:, date: it).id } }
    admin = User.last
    as_admin = -> { integration_session.bearer_token = nil
                    sign_in_as(admin) }
    kumar = driver_token("91234567")
    open = lambda do
      bell(kumar)[:data].filter_map { |l| l[:run] && [ l[:kind], l.dig(:run, :id), l.dig(:run, :open) ] }
    end
    expect(open.call).to eq([ [ "run_assigned", tomorrow, true ], [ "run_assigned", today, true ] ])

    # From tomorrow on the slot goes to Siti's bus: the run is no longer Kumar's.
    as_admin.call
    get api_v1_trip_assignments_path(trip_id)
    slot = json.dig(:data, :slots, 0, :key)
    post api_v1_trip_assignments_path(trip_id), params: { effective_from: "2026-11-04", slots: [ slot ], assignee: "own", vehicle_id: f[:b].id }, as: :json
    expect(response).to have_http_status(:created)
    expect(open.call).to eq([ [ "run_unassigned", tomorrow, false ], [ "run_assigned", tomorrow, false ], [ "run_assigned", today, true ] ])
    get api_v1_driver_app_run_path(tomorrow), headers: as(kumar)
    expect(response).to have_http_status(:not_found)

    # Today: cancelled, then back on and taken by a replacement (Replaced) — Trip Details still opens.
    within_tenant(company) { Occurrences::Edit.new(TripOccurrence.find_by!(id: today), admin).cancel! }
    expect(open.call.select { it[1] == today }).to eq([ [ "run_cancelled", today, true ], [ "run_assigned", today, true ] ])
    within_tenant(company) { Occurrences::Edit.new(TripOccurrence.find_by!(id: today), admin).restore! }
    as_admin.call
    post api_v1_replacements_path, params: { occurrence_id: today, replacement: { kind: "crew", vehicle_id: f[:b].id } }, as: :json
    expect(open.call.select { it[1] == today }.first(2)).to eq([ [ "run_unassigned", today, true ], [ "run_changed", today, true ] ])

    # The assignment is taken back: tomorrow's run is Kumar's again, so its old lines open again.
    as_admin.call
    get api_v1_trip_assignments_path(trip_id)
    delete api_v1_trip_assignment_path(trip_id, json.dig(:data, :history, 0, :id))
    expect(open.call.select { it[1] == tomorrow }.map(&:last).uniq).to eq([ true ])

    # One query for the whole page, however many run lines.
    n = 0
    cb = ->(*, payload) { n += 1 if payload[:sql].include?("trip_occurrences") }
    ActiveSupport::Notifications.subscribed(cb, "sql.active_record") { bell(kumar) }
    expect(n).to eq(1)

    # The trip is deleted: the runs are removed, nothing opens.
    as_admin.call
    delete api_v1_trip_path(trip_id)
    expect(open.call.map(&:last).uniq).to eq([ false ])
  end

  it "sends notices: Open ones read when opened, Acknowledge ones until acknowledged" do
    ack, view = within_tenant(company) do
      [ DriverNotice.create!(kind: "ack", title: "Route change from Friday", summary: "Drop at the main gate. Please acknowledge.",
                             body: "From Friday 31 Oct the side gate is closed…", from_name: "SimpleDrive Operations", starts_at: Time.current),
        DriverNotice.create!(kind: "view", title: "New depot map", summary: "Buses 20 to 48 park in the new row.", link_url: "https://simpledrive.sg/depot",
                             link_label: "Depot map (PDF)", starts_at: Time.current - 1.hour) ].each { DriverNotices::Publish.call(notice: it) }
    end
    kumar = driver_token("91234567")
    expect(bell(kumar)[:data].map { [ it[:title], it[:read], it.dig(:notice, :kind) ] })
      .to eq([ [ "Route change from Friday", false, "ack" ], [ "New depot map", false, "view" ] ])

    post read_all_api_v1_driver_app_notifications_path, headers: as(kumar)
    expect(bell(kumar)[:data].map { it[:read] }).to eq([ false, true ])

    get api_v1_driver_app_notice_path(view.id), headers: as(kumar)
    expect(json[:data]).to include(kind: "view", link: { url: "https://simpledrive.sg/depot", label: "Depot map (PDF)" }, needs_ack: false, read_at: be_present)
    post acknowledge_api_v1_driver_app_notice_path(view.id), headers: as(kumar)
    expect(json.dig(:error, :message)).to eq("This notice needs no acknowledgement")

    get api_v1_driver_app_notice_path(ack.id), headers: as(kumar)
    expect(json[:data]).to include(needs_ack: true, acknowledged_at: nil, from_name: "SimpleDrive Operations")
    expect(bell(kumar)[:meta]).to eq(unread: 1)
    post acknowledge_api_v1_driver_app_notice_path(ack.id), headers: as(kumar)
    expect(json[:data]).to include(needs_ack: false, acknowledged_at: be_present)
    expect(bell(kumar)[:meta]).to eq(unread: 0)
    expect(bell(kumar).dig(:data, 0, :notice, :acknowledged_at)).to be_present
    expect(within_tenant(company) { ack.recipients.find_by(driver: f[:kumar]).acknowledged_at }).to be_present

    other = within_tenant(company) { DriverNotice.create!(kind: "view", title: "Siti only", starts_at: Time.current).tap { DriverNotices::Publish.call(notice: it, members: [ f[:siti] ]) } }
    get api_v1_driver_app_notice_path(other.id), headers: as(kumar)
    expect(response).to have_http_status(:not_found)
  end
end
