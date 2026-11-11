require "rails_helper"

# Client Portal › Map (today): the client's own runs by activity (school sessions, Bookings, Shuttles), where each is,
# the bus position only while it runs for this client, Members' one-off trips only from their own bookings, a School
# Bus run in detail with its students, and finding a student.
RSpec.describe "Client Portal map" do
  let(:company) { create(:company, code: "SD") }
  let!(:f) do
    within_tenant(company) do
      bus = create(:vehicle, plate: "PD6604E", seats: 40, make: "Yutong", model: "ZK6107")
      school = School.create!(name: "Bright Steps (Punggol)", short_name: "BSP", lat: 1.4043, lng: 103.9020)
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
      school.riders.create!(rid: "K-1", name: "Aisha Tan", grade: "K2", postal: "820101", am: true, pm: true, source: "manual")
      am = school.plans.create!(name: "AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
      r1 = am.routes.create!(number: 1, label: "AM 1", start_time: "07:00", end_time: "07:40", bus_type: "LARGE_40", seats: 40)
      s1 = r1.stops.create!(position: 0, name: "Blk 101 Punggol Field", scheduled_time: "07:00", lat: 1.3984, lng: 103.9072)
      SchoolRouteRider.create!(school_route: r1, stop: s1, rid: "K-1")
      r1.vehicle_changes.create!(vehicle: bus, effective_from: Date.new(2026, 10, 1))

      client = create(:client, name: "Bright Steps")
      punggol = client.sites.create!(company_id: company.id, name: "Punggol", school:, lat: 1.4043, lng: 103.9020)
      tampines = client.sites.create!(company_id: company.id, name: "Tampines")
      shuttle = create(:trip, client:, client_site: punggol, title: "Staff Shuttle", start_time: "07:30", end_time: "08:00",
                              days: [ 1, 2, 3, 4, 5 ], end_mode: "never", starts_on: Date.new(2026, 10, 1))
      shuttle.update_columns(kind: "corporate_shuttle") # rubocop:disable Rails/SkipsModelValidations
      excursion = create(:trip, client:, client_site: tampines, title: "Zoo Excursion", start_time: "09:00", end_time: "12:00", starts_on: Date.new(2026, 11, 3))
      { school:, r1:, bus:, client:, punggol:, tampines:, shuttle:, excursion:,
        admin: portal_user(client, email: "ann@brightsteps.sg", role: "adm"),
        sa_p: portal_user(client, email: "pat@brightsteps.sg", role: "sa", sites: [ punggol ]),
        mo_t: portal_user(client, email: "mo@brightsteps.sg", role: "member", sites: [ tampines ]) }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 3, 5, 0)
    within_tenant(company) { Occurrences::Sync.call(routes: SchoolRoute.all.to_a) }
    travel_to Time.zone.local(2026, 11, 3, 7, 20)
    within_tenant(company) do
      day = Date.new(2026, 11, 3)
      run = ->(trip, kind, from, to, **extra) do
        TripOccurrence.create!(trip:, client: f[:client], date: day, start_time: from * 60, end_time: to * 60, starts_at: day.in_time_zone.change(hour: from),
                               ends_at: day.in_time_zone.change(hour: to), kind:, trip_label: "#{trip.title} #{from}", run_key: "r#{trip.id}", **extra)
      end
      run.(f[:shuttle], "corporate_shuttle", 8, 9, vehicle: f[:bus], started_at: Time.zone.local(2026, 11, 3, 7, 15))
      run.(f[:excursion], "ad_hoc", 9, 12)
      VehicleLivePosition.create!(vehicle: f[:bus], lat: 1.3984, lng: 103.9072, speed_kmh: 25, heading: 90, recorded_at: Time.zone.local(2026, 11, 3, 7, 19))
    end
  end

  # A one-off trip made from a Portal booking (the only kind the Bookings activity lists), confirmed for today.
  def book(user, site, start_time: "15:00")
    within_tenant(company) do
      type = VehicleType.first || create(:vehicle_type, name: "13-seater", seats: 13)
      RateCards::Save.call(card: RateCard.new, params: RateCards::Standard.params(name: "Standard", types: [ type ])) unless RateCard.exists?
      booking = Portal::SubmitBooking.call(client_user: user, params: {
        client_site_id: site.id, coordinator_name: "Coordinator", days: [ { date: "2026-11-03", trips: [
          { kind: "one_way", start_time:, pax: 5, points: [ { name: "Tampines Hub", use: "pu" }, { name: "Jurong Bird Park", use: "do" } ],
            vehicles: [ { vehicle_type_id: type.id, count: 1 } ] } ] } ]
      })
      Bookings::Approve.call(trip: booking.trips.first, user: create(:user, :admin, company:), trip_value: 1)
      booking
    end
  end

  it "shows the activities and the runs of one, with the bus only while it runs for the client" do
    get api_v1_portal_map_path, params: { activity: "shuttles" }, headers: as(portal_token(f[:admin]))
    d = json[:data]
    expect(d[:activities].pluck(:key, :count)).to eq([ [ "am", 1 ], [ "shuttles", 1 ] ]) # the Zoo trip has no booking: not under Bookings
    expect(d[:schools].pluck(:name)).to eq([ "Bright Steps (Punggol)" ])
    run = d[:runs].first
    expect(run).to include(title: "Staff Shuttle", state: "on_the_way", bus: { plate: "PD6604E", model: "Yutong ZK6107", seats: 40 },
                           position: hash_including(lat: 1.3984, speed_kmh: 25), site: { id: f[:punggol].id, name: "Punggol" })
    expect(d[:counts]).to include(on_the_way: 1)

    booking = book(f[:admin], f[:tampines])
    get api_v1_portal_map_path, params: { activity: "bookings" }, headers: as(portal_token(f[:admin]))
    brun = json.dig(:data, :runs, 0)
    expect(brun).to include(state: "scheduled", position: nil, booking: { id: booking.id, number: booking.number })

    get api_v1_portal_map_run_path(brun[:id]), headers: as(portal_token(f[:admin])), as: :json
    expect(json.dig(:data, :stops).pluck(:name)).to eq([ "Tampines Hub", "Jurong Bird Park" ])
  end

  it "lists under Bookings only trips made from a Portal booking, with the booking always set, and falls back to the first stop site" do
    get api_v1_portal_map_path, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :activities).pluck(:key)).not_to include("bookings") # the Zoo trip was made in Convoy OS
    get api_v1_portal_map_run_path(within_tenant(company) { f[:excursion].occurrences.first.id }), headers: as(portal_token(f[:admin])), as: :json
    expect(response).to have_http_status(:not_found)

    booking = book(f[:admin], f[:tampines])
    get api_v1_portal_map_path, params: { activity: "bookings" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :runs).pluck(:booking)).to all(include(number: booking.number))
    expect(json.dig(:data, :runs, 0, :site)).to eq(id: f[:tampines].id, name: "Tampines")

    # A booking trip with no site of its own takes the first stop that has one; with none, site stays null.
    within_tenant(company) do
      trip = booking.trips.first.scheduler_trips.first
      trip.update_columns(client_site_id: nil) # rubocop:disable Rails/SkipsModelValidations
      trip.stops.update_all(client_site_id: nil) # rubocop:disable Rails/SkipsModelValidations
      trip.stops.order(:position).last.update_columns(client_site_id: f[:punggol].id) # rubocop:disable Rails/SkipsModelValidations
    end
    get api_v1_portal_map_path, params: { activity: "bookings" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :runs, 0, :site)).to eq(id: f[:punggol].id, name: "Punggol")
    within_tenant(company) { booking.trips.first.scheduler_trips.first.stops.update_all(client_site_id: nil) } # rubocop:disable Rails/SkipsModelValidations
    get api_v1_portal_map_path, params: { activity: "bookings" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :runs, 0)).to include(site: nil, booking: hash_including(:number))
  end

  it "limits runs to the person's sites, and Members to one-off trips from their own bookings" do
    get api_v1_portal_map_path, headers: as(portal_token(f[:sa_p]))
    expect(json.dig(:data, :activities).pluck(:key)).to eq(%w[am shuttles])
    get api_v1_portal_map_path, headers: as(portal_token(f[:mo_t]))
    expect(json.dig(:data, :activities)).to eq([]) # the Zoo trip is not from their booking; no shuttle at Tampines
    book(f[:admin], f[:tampines]) # someone else's booking at their site: still not theirs
    get api_v1_portal_map_path, headers: as(portal_token(f[:mo_t]))
    expect(json.dig(:data, :activities)).to eq([])
    get api_v1_portal_map_run_path(within_tenant(company) { f[:shuttle].occurrences.first.id }), headers: as(portal_token(f[:mo_t])), as: :json
    expect(response).to have_http_status(:not_found)

    # Their own booking, confirmed: its run shows under Bookings.
    book(f[:mo_t], f[:tampines], start_time: "16:00")
    get api_v1_portal_map_path, headers: as(portal_token(f[:mo_t]))
    expect(json.dig(:data, :activities).pluck(:key, :count)).to eq([ [ "bookings", 1 ] ])
    expect(json.dig(:data, :runs, 0)).to include(booking: hash_including(number: start_with("SD26")), state: "scheduled")
  end

  it "shows a School Bus run with its students, and finds a student" do
    get api_v1_portal_map_path, params: { activity: "am" }, headers: as(portal_token(f[:sa_p]))
    run = json.dig(:data, :runs, 0)
    expect(run).to include(kind: "school_bus", label: "AM 1", school: hash_including(name: "Bright Steps (Punggol)"))

    get api_v1_portal_map_run_path(run[:id]), headers: as(portal_token(f[:sa_p])), as: :json
    expect(json.dig(:data, :stops, 0, :name)).to eq("Blk 101 Punggol Field")

    get api_v1_portal_map_students_path, params: { q: "aisha" }, headers: as(portal_token(f[:sa_p]))
    expect(json[:data]).to contain_exactly(hash_including(name: "Aisha Tan", level: "K2", session: "am", route: "AM 1", plate: "PD6604E",
                                                          stop: "Blk 101 Punggol Field", status: "waiting"))
  end

  it "counts a School Bus session from its own rows, and words the kind of each run as the prototype does" do
    get api_v1_portal_map_path, params: { activity: "am" }, headers: as(portal_token(f[:admin]))
    d = json[:data]
    # 07:20 is inside the 30 minutes before the planned start, but no driver has started: the pill says what the row says.
    expect(d[:activities].find { it[:key] == "am" }).to eq(key: "am", label: "AM", count: 1, on_road: 0)
    expect(d[:counts]).to include(scheduled: 1, on_the_way: 0, started: 0)
    expect(d[:runs].first).to include(kind: "school_bus", kind_label: "School bus, morning", state: "scheduled")

    get api_v1_portal_map_path, params: { activity: "shuttles" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :runs, 0)).to include(kind: "corporate_shuttle", kind_label: "Shuttle, morning")
    book(f[:admin], f[:tampines])
    get api_v1_portal_map_path, params: { activity: "bookings" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :runs, 0)).to include(kind: "ad_hoc", kind_label: be_present)
  end

  it "answers a School Bus run with the list row's fields, students at each stop, and the position only while it runs" do
    token = portal_token(f[:sa_p])
    get api_v1_portal_map_path, params: { activity: "am" }, headers: as(token)
    row = json.dig(:data, :runs, 0)
    get api_v1_portal_map_run_path(row[:id]), headers: as(token), as: :json
    d = json[:data]
    expect(d).to include(id: row[:id], kind: "school_bus", kind_label: "School bus, morning", title: "Bright Steps (Punggol) AM 1",
                         school: { id: f[:school].id, name: "Bright Steps (Punggol)" }, bus: hash_including(plate: "PD6604E"), state: "scheduled",
                         state_label: "Scheduled", position: nil)
    expect(d[:stops].first).not_to have_key(:riders)
    expect(d[:stops].first[:students]).to contain_exactly(hash_including(name: "Aisha Tan"))

    # The bus has a position and the run is not on the road: still no position. Once started, it shows.
    within_tenant(company) do
      VehicleLivePosition.find_by!(vehicle: f[:bus]).update!(recorded_at: Time.zone.local(2026, 11, 3, 7, 19))
      TripOccurrence.find(row[:id]).update!(started_at: Time.zone.local(2026, 11, 3, 7, 5))
    end
    get api_v1_portal_map_run_path(row[:id]), headers: as(token), as: :json
    expect(json[:data]).to include(state: "started", position: hash_including(lat: 1.3984))
  end

  it "takes a run's site from the first stop site in view when the trip has none" do
    within_tenant(company) do
      trip = create(:trip, client: f[:client], client_site: nil, title: "Cross-site Shuttle", start_time: "10:00", end_time: "11:00", days: [ 1, 2, 3, 4, 5 ],
                           end_mode: "never", starts_on: Date.new(2026, 10, 1))
      trip.update_columns(kind: "corporate_shuttle") # rubocop:disable Rails/SkipsModelValidations
      trip.stops.each_with_index { |stop, i| stop.update_columns(client_site_id: (i.zero? ? f[:tampines] : f[:punggol]).id) } # rubocop:disable Rails/SkipsModelValidations
      day = Date.new(2026, 11, 3)
      TripOccurrence.create!(trip:, client: f[:client], date: day, start_time: 600, end_time: 660, starts_at: day.in_time_zone.change(hour: 10),
                             ends_at: day.in_time_zone.change(hour: 11), kind: "corporate_shuttle", trip_label: "X10", run_key: "x10")
    end
    row = ->(token) { get api_v1_portal_map_path, params: { activity: "shuttles" }, headers: as(token); json.dig(:data, :runs).find { it[:title] == "Cross-site Shuttle" } }
    expect(row.(portal_token(f[:admin]))[:site]).to eq(id: f[:tampines].id, name: "Tampines")
    expect(row.(portal_token(f[:sa_p]))[:site]).to eq(id: f[:punggol].id, name: "Punggol") # Tampines is not theirs
  end
end
