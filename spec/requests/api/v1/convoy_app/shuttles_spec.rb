require "rails_helper"

# Convoy App › Shuttles (staff rider): routes of the employers a person has a live link with, tag chips, My Usual Shuttle, pins,
# the route page (14-day strip, timings, buses, changes), View Schedule, Alert Settings, Pause Alerts and the change alerts the
# job writes into the inbox. Today is Monday 16/11/2026 05:00 in the company's time zone.
RSpec.describe "Convoy App shuttles" do
  let(:today) { Date.new(2026, 11, 16) }
  let(:tomorrow) { today + 1 }
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:other_company) { create(:company, name: "Other Transport") }

  let!(:f) do
    within_tenant(company) do
      client = create(:client, name: "Google Asia Pacific", email_domains: %w[google.com])
      site = client.sites.create!(company_id: company.id, name: "Mapletree Business City")
      type = create(:vehicle_type, seats: 23)
      bus1 = create(:vehicle, plate: "PC8841T", make: "Mitsubishi", model: "Rosa")
      bus2 = create(:vehicle, plate: "PD4472H")
      spare = create(:vehicle, plate: "PD5126A", make: "Toyota", model: "Coaster")
      driver = create(:driver, name: "Daniel Wong")
      admin = create(:user, :admin, company:)
      trip = Trips::Save.call(trip: Trip.new, user: admin, attributes: {
        kind: "corporate_shuttle", client_id: client.id, title: "MBC Campus Shuttle", label: "mbc", starts_on: "2026-11-02", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
        vehicles_count: 2, shuttle_return: true, price_by: "all", price_basis: "trip", route_tags: "Campus, Staff", trip_value: 1, trip_value_return: 1,
        stops_attributes: [
          { position: 0, name: "Labrador Park MRT", use: "pu", lat: 1.2722, lng: 103.8026, address: "Exit A" },
          { position: 1, name: "Alexandra Road", use: "both", lat: 1.2779, lng: 103.8009 },
          { position: 2, name: "Mapletree Business City", use: "do", lat: 1.2747, lng: 103.7993, client_site_id: site.id }
        ],
        vehicle_requirements_attributes: [ { vehicle_type_id: type.id, count: 2 } ],
        runs_attributes: [
          { direction: 1, position: 0, times: %w[07:30 07:40 07:55], slots_attributes: [ { slot_no: 1, vehicle_id: bus1.id }, { slot_no: 2, vehicle_id: bus2.id } ] },
          { direction: 1, position: 1, times: %w[08:30 08:40 08:55], slots_attributes: [ { slot_no: 1, vehicle_id: bus1.id }, { slot_no: 2, vehicle_id: bus2.id } ] },
          { direction: 2, position: 0, times: %w[18:00 18:10 18:25], slots_attributes: [ { slot_no: 1, vehicle_id: bus1.id }, { slot_no: 2, vehicle_id: bus2.id } ] }
        ],
        price_table: [ { row: "all", col: "all", amount: 50 } ]
      }).trip
      { client:, site:, trip:, admin:, bus1:, bus2:, spare:, driver:, am1: trip.runs.find { it.direction == 1 && it.position.zero? }, am2: trip.runs.find { it.direction == 1 && it.position == 1 },
        pm: trip.runs.find { it.direction == 2 }, alexandra: trip.stops.find { it.name == "Alexandra Road" }, labrador: trip.stops.find { it.name == "Labrador Park MRT" } }
    end
  end

  # An account (a mobile, a work email on google.com) with the staff link accepted; after `travel_to`, tokens are signed in now.
  def rider(mobile: "9188 2045", email: "rachel@google.com", accept: true, mark: :accepted)
    account, token = app_user(mobile:)
    app_add_identity(token, kind: "email", value: email, tag: "work")
    link = ActsAsTenant.without_tenant { ClientRider.find_by!(app_account_id: account.id) }
    post "/api/v1/app/organisations/shuttle/#{link.id}/accept", headers: app_as(token), as: :json if accept
    expect(response).to have_http_status(:ok), json.inspect if accept
    { account:, token:, link: link.reload, h: app_as(token), mark: }
  end

  def shuttles(r, **params) = get("/api/v1/app/shuttles", params:, headers: r[:h]) && json[:data]
  def route(r, id = f[:trip].id, **params) = get("/api/v1/app/shuttles/#{r[:link].id}/routes/#{id}", params:, headers: r[:h]) && json
  def base(r) = "/api/v1/app/shuttles/#{r[:link].id}"

  def occurrence(run, date, slot = 1) = within_tenant(company) { TripOccurrence.find_by!(trip_id: f[:trip].id, date:, trip_run_id: run.id, slot_no: slot, part: 1) }

  before { travel_to Time.zone.local(2026, 11, 16, 5, 0) }

  describe "who sees an employer" do
    it "shows nothing without an accepted link, nothing for an invited link, and 404 for another person's employer" do
      a = rider(accept: false)
      expect(shuttles(a)).to include(employers: [], routes: [])
      route(a)
      expect(response).to have_http_status(:not_found)

      b = rider(mobile: "9177 3301", email: "david@google.com")
      expect(shuttles(b)[:routes].pluck(:name)).to eq([ "MBC Campus Shuttle" ])
      get "#{base(b)}/routes/#{f[:trip].id}", headers: a[:h]
      expect(response).to have_http_status(:not_found)
    end

    it "shows nothing once the office removed the link, or the work email is past its 12-month check" do
      a = rider
      expect(shuttles(a)[:employers].pluck(:name)).to eq([ "Google Asia Pacific" ])

      a[:account].identities.find_by!(value: "rachel@google.com").update!(verified_at: 13.months.ago)
      expect(shuttles(a)).to include(employers: [], routes: [])
      get "#{base(a)}/routes/#{f[:trip].id}", headers: a[:h]
      expect(response).to have_http_status(:not_found)

      a[:account].identities.find_by!(value: "rachel@google.com").update!(verified_at: Time.current)
      expect(shuttles(a)[:employers].size).to eq(1)
      ActsAsTenant.without_tenant { a[:link].update!(status: "removed") }
      expect(shuttles(a)).to include(employers: [], routes: [])
    end

    it "does not show the routes of another client or another company on the same domain" do
      within_tenant(company) do
        other = create(:client, name: "Meta")
        meta = create(:trip, client: other, title: "Meta Shuttle", days: [ 1 ], end_mode: "never")
        meta.update_columns(kind: "corporate_shuttle") # rubocop:disable Rails/SkipsModelValidations
      end
      within_tenant(other_company) { create(:client, name: "Google Other Co", email_domains: %w[google.com]) }
      expect(shuttles(rider)[:routes].pluck(:name)).to eq([ "MBC Campus Shuttle" ])
    end
  end

  describe "the route list" do
    it "gives the chips (All, Pinned, site names and route tags), filters by tag, and says Next from today's runs" do
      r = rider
      data = shuttles(r)
      expect(data[:tags]).to eq([ "All", "Pinned", "Campus", "Mapletree Business City", "Staff" ])
      card = data[:routes].first
      expect(card).to include(name: "MBC Campus Shuttle", pinned: false, tags: a_collection_containing_exactly("Mapletree Business City", "Campus", "Staff"))
      expect(card[:directions]).to eq([ { direction: 1, name: "Morning", timings: 2, first: "07:30", last: "08:30" }, { direction: 2, name: "Evening", timings: 1, first: "18:00", last: "18:00" } ])
      expect(card[:now]).to eq(state: "next", time: "07:30")

      expect(shuttles(r, tag: "staff")[:routes].size).to eq(1)
      expect(shuttles(r, tag: "Mapletree Business City")[:routes].size).to eq(1)
      expect(shuttles(r, tag: "Cross-site")[:routes]).to eq([])
      expect(shuttles(r, tag: "Pinned")[:routes]).to eq([])
    end

    it "pins and unpins by value, so a repeated tap never flips it back" do
      r = rider
      2.times do
        put "#{base(r)}/routes/#{f[:trip].id}/pin", params: { pinned: true }, headers: r[:h], as: :json
        expect(json[:data]).to eq(pinned: true)
      end
      expect(shuttles(r, tag: "Pinned")[:routes].pluck(:pinned)).to eq([ true ])
      put "#{base(r)}/routes/#{f[:trip].id}/pin", params: { pinned: false }, headers: r[:h], as: :json
      expect(shuttles(r, tag: "Pinned")[:routes]).to eq([])
      expect(ActsAsTenant.without_tenant { ShuttlePin.count }).to eq(0)
    end

    it "says Done for today once every run has ended or was cancelled, and None when nothing runs" do
      r = rider
      travel_to Time.zone.local(2026, 11, 16, 20, 0)
      r[:h] = app_as(app_token(mobile: "9188 2045"))
      expect(shuttles(r)[:routes].first[:now]).to eq(state: "done")
      travel_to Time.zone.local(2026, 11, 21, 8, 0) # a Saturday
      r[:h] = app_as(app_token(mobile: "9188 2045"))
      expect(shuttles(r)[:routes].first[:now]).to eq(state: "none")
    end
  end

  describe "My Usual Shuttle" do
    it "lists boarding stops, saves a usual (one per employer), shows it on the list and the route, and clears it" do
      r = rider
      get "#{base(r)}/usual", headers: r[:h]
      route_opts = json.dig(:data, :routes, 0, :directions)
      expect(route_opts.first).to include(direction: 1, timings: [ { run_id: f[:am1].id, time: "07:30" }, { run_id: f[:am2].id, time: "08:30" } ])
      expect(route_opts.first[:stops].pluck(:name)).to eq([ "Labrador Park MRT", "Alexandra Road" ]) # not the drop-off only stop
      expect(route_opts.last[:stops].pluck(:name)).to eq([ "Mapletree Business City", "Alexandra Road" ])

      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am2].id, stop_id: f[:alexandra].id }, headers: r[:h], as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json.dig(:data, :usual)).to include(run_id: f[:am2].id, stop_id: f[:alexandra].id, direction: 1)
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am1].id }, headers: r[:h], as: :json # still one row: stop falls back to the first boarding stop
      expect(ActsAsTenant.without_tenant { ShuttleUsual.pluck(:trip_run_id, :trip_stop_id) }).to eq([ [ f[:am1].id, f[:labrador].id ] ])

      expect(shuttles(r)[:usual]).to include(route: "MBC Campus Shuttle", time: "07:30", stop: "Labrador Park MRT")
      page = route(r)[:data]
      expect(page[:usual]).to include(run_id: f[:am1].id, time: "07:30")
      expect(page[:timing]).to include(run_id: f[:am1].id)
      expect(page[:timing][:stops].find { it[:my_stop] }).to include(name: "Labrador Park MRT", bell: true)

      delete "#{base(r)}/usual", headers: r[:h]
      expect(json.dig(:data, :usual)).to be_nil
    end

    it "asks for a timing and refuses a stop that is not a boarding stop or a timing of another route" do
      r = rider
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id }, headers: r[:h], as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Pick your usual timing")
      mbc = f[:trip].stops.find { it.name == "Mapletree Business City" }
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am1].id, stop_id: mbc.id }, headers: r[:h], as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Pick where you board")
    end

    it "follows the usual run's direction: the usual stop is the default bell, and a bell can be switched off by value" do
      r = rider
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am1].id, stop_id: f[:alexandra].id }, headers: r[:h], as: :json
      stops = ->(**p) { route(r, **p)[:data][:timing][:stops] }
      expect(stops.call.pluck(:bell)).to eq([ false, true, false ])
      put "#{base(r)}/routes/#{f[:trip].id}/stops/#{f[:alexandra].id}/bell", params: { direction: 1, on: false }, headers: r[:h], as: :json
      put "#{base(r)}/routes/#{f[:trip].id}/stops/#{f[:labrador].id}/bell", params: { direction: 1, on: true }, headers: r[:h], as: :json
      expect(stops.call.pluck(:bell)).to eq([ true, false, false ])
      expect(stops.call(direction: 2).pluck(:bell)).to eq([ false, false, false ]) # bells are per direction
    end
  end

  describe "the route page" do
    it "gives the 14-day strip (weekend off, public holiday off with the day it resumes), the timings, buses, stops and the next change" do
      within_tenant(company) do
        PublicHoliday.create!(company:, date: today + 3, name: "Deepavali")
        Occurrences::Sync.call(trips: [ f[:trip] ])
      end
      page = route(rider)[:data]
      expect(page).to include(date: "2026-11-16", direction: 1, direction_name: "Morning", selected_run_id: f[:am1].id)
      expect(page[:strip].size).to eq(14)
      by = page[:strip].index_by { it[:date] }
      expect(by["2026-11-16"]).to include(state: "service", reason: nil)
      expect(by["2026-11-19"]).to include(state: "no_service", reason: a_kind_of(String), resumes_on: "2026-11-20")
      expect(by["2026-11-21"]).to include(state: "no_service", reason: "Weekend", resumes_on: "2026-11-23")
      expect(page[:next_change]).to include(date: "2026-11-19", state: "no_service")

      expect(page[:timings].pluck(:run_id, :time, :state, :buses)).to eq([ [ f[:am1].id, "07:30", "scheduled", 2 ], [ f[:am2].id, "08:30", "scheduled", 2 ] ])
      timing = page[:timing]
      expect(timing[:buses].pluck(:plate)).to eq([ "PC8841T", "PD4472H" ]) # every vehicle of the timing
      expect(timing[:buses].first).to include(description: "Mitsubishi Rosa", change: nil)
      expect(timing[:stops].pluck(:name, :planned_time, :boarding, :alighting)).to eq([ [ "Labrador Park MRT", "07:30", true, false ], [ "Alexandra Road", "07:40", true, true ], [ "Mapletree Business City", "07:55", false, true ] ])
      expect(timing[:stops].first).to include(address: "Exit A", done: false, next: false)
      expect(timing[:line].size).to eq(3)
    end

    it "swaps pick-up and drop-off on the evening direction, and hides times on a day with no service" do
      r = rider
      page = route(r, direction: 2)[:data]
      expect(page[:timing][:stops].pluck(:name, :boarding, :alighting)).to eq([ [ "Mapletree Business City", true, false ], [ "Alexandra Road", true, true ], [ "Labrador Park MRT", false, true ] ])
      saturday = route(r, date: "2026-11-21")[:data]
      expect(saturday).to include(timing: nil, timings: [])
      expect(saturday[:day]).to include(state: "no_service", reason: "Weekend")
      expect(saturday[:stops].pluck(:name, :time)).to eq([ [ "Labrador Park MRT", nil ], [ "Alexandra Road", nil ], [ "Mapletree Business City", nil ] ])
    end

    it "shows the calendar's changed times on the strip and the timing" do
      within_tenant(company) do
        TripTimeChange.create!(trip: f[:trip], effective_from: today + 1, minutes: -60, company_id: company.id)
        Occurrences::Sync.call(trips: [ f[:trip] ])
      end
      page = route(rider, date: tomorrow.iso8601)[:data]
      expect(page[:day]).to include(state: "changed", shifts: [ { direction: 1, name: "Morning", minutes: -60 }, { direction: 2, name: "Evening", minutes: -60 } ])
      expect(page[:timings].pluck(:time)).to eq([ "06:30", "07:30" ])
      expect(page[:timings].first).to include(shift_minutes: -60)
    end

    it "refuses a date outside today … today + 92 days, and a direction the route does not run" do
      r = rider
      get "#{base(r)}/routes/#{f[:trip].id}", params: { date: "2026-11-15" }, headers: r[:h]
      expect(response).to have_http_status(:unprocessable_content)
      get "#{base(r)}/routes/#{f[:trip].id}", params: { date: "nonsense" }, headers: r[:h]
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "changes on a run" do
    let(:day) { tomorrow }

    def save_replacement(attrs, occ)
      within_tenant(company) { Replacements::Save.call(replacement: Replacement.new, attributes: attrs, user: f[:admin], occurrence: occ) }
    end

    it "shows another bus (with the usual bus and when the rider is alerted), a relief driver, a cancelled run with the next bus, on any day of the strip" do
      r = rider
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am1].id, stop_id: f[:alexandra].id }, headers: r[:h], as: :json
      save_replacement({ kind: "veh", vehicle_id: f[:spare].id }, occurrence(f[:am1], day, 1))
      save_replacement({ kind: "drv", driver_id: f[:driver].id }, occurrence(f[:am1], day, 2))
      within_tenant(company) { Occurrences::Edit.new(occurrence(f[:am2], day, 1), f[:admin]).cancel! }
      within_tenant(company) { Occurrences::Edit.new(occurrence(f[:am2], day, 2), f[:admin]).cancel! }

      page = route(r, date: day.iso8601)[:data]
      expect(page[:strip].find { it[:date] == day.iso8601 }[:changes]).to contain_exactly("bus", "driver", "cancelled")
      first, second = page[:timings]
      expect(first).to include(change: "bus", state: "scheduled")
      expect(second).to include(change: "cancelled", state: "cancelled")

      buses = page[:timing][:buses]
      expect(buses[0]).to include(plate: "PD5126A", change: a_hash_including(kind: "bus", usual_bus: a_hash_including(plate: "PC8841T", description: "Mitsubishi Rosa")))
      expect(buses[0][:change][:alert]).to include(stop: "Alexandra Road", alerted_at: nil)
      expect(Time.zone.parse(buses[0][:change][:alert][:alert_at])).to eq(Time.zone.local(2026, 11, 17, 6, 40)) # 07:40 at Alexandra Road − 1 hour
      expect(buses[1]).to include(plate: "PD4472H", driver: a_hash_including(name: "Daniel Wong", relief: true), change: a_hash_including(kind: "driver"))

      cancelled = route(r, date: day.iso8601, run_id: f[:am2].id)[:data][:timing]
      expect(cancelled).to include(state: "cancelled")
      expect(cancelled[:status][:next_bus]).to be_nil # the 08:30 was the last morning timing
      expect(cancelled[:buses].pluck(:change)).to all(a_hash_including(kind: "cancelled", by: "SimpleDrive"))
    end

    it "says which timing is the next bus when an earlier one is cancelled" do
      within_tenant(company) { [ 1, 2 ].each { |slot| Occurrences::Edit.new(occurrence(f[:am1], day, slot), f[:admin]).cancel! } }
      status = route(rider, date: day.iso8601, run_id: f[:am1].id)[:data][:timing][:status]
      expect(status[:next_bus]).to include(run_id: f[:am2].id, time: "08:30", from: "Labrador Park MRT")
    end

    it "never shows a bus change on a No Fixed Bus route, and shows no change when the regular bus runs" do
      save_replacement({ kind: "veh", vehicle_id: f[:spare].id }, occurrence(f[:am1], day, 1))
      within_tenant(company) { f[:trip].update_columns(no_fixed_bus: true) } # rubocop:disable Rails/SkipsModelValidations
      r = rider
      buses = route(r, date: day.iso8601)[:data][:timing][:buses]
      expect(buses[0]).to include(plate: "PD5126A", no_fixed_bus: true, change: nil)
      expect(route(r, date: (day + 1).iso8601)[:data][:timing][:buses].pluck(:change)).to eq([ nil, nil ])
    end
  end

  describe "View Schedule" do
    it "gives the month with its off days and the timetable of the picked day, limited to this month … today + 92 days" do
      within_tenant(company) { PublicHoliday.create!(company:, date: today + 3, name: "Deepavali") && Occurrences::Sync.call(trips: [ f[:trip] ]) }
      r = rider
      get "#{base(r)}/routes/#{f[:trip].id}/schedule", params: { direction: 1 }, headers: r[:h]
      data = json[:data]
      expect(data).to include(month: "2026-11", first_month: "2026-11", last_month: "2027-02", date: "2026-11-16")
      days = data[:days].index_by { it[:date] }
      expect(days["2026-11-15"]).to include(past: true, state: "no_service")
      expect(days["2026-11-19"]).to include(state: "no_service", past: false)
      expect(days["2026-11-17"]).to include(state: "service", changes: [])
      expect(data[:timetable][:stops].pluck(:name)).to eq([ "Labrador Park MRT", "Alexandra Road", "Mapletree Business City" ])
      expect(data[:timetable][:timings].pluck(:time, :times)).to eq([ [ "07:30", %w[07:30 07:40 07:55] ], [ "08:30", %w[08:30 08:40 08:55] ] ])

      get "#{base(r)}/routes/#{f[:trip].id}/schedule", params: { direction: 1, month: "2027-02", date: "2027-02-10" }, headers: r[:h]
      expect(json[:data][:month]).to eq("2027-02")
      get "#{base(r)}/routes/#{f[:trip].id}/schedule", params: { month: "2027-03" }, headers: r[:h]
      expect(response).to have_http_status(:unprocessable_content)
      get "#{base(r)}/routes/#{f[:trip].id}/schedule", params: { date: "2026-11-19" }, headers: r[:h]
      expect(json.dig(:data, :timetable)).to include(timings: [], day: a_hash_including(state: "no_service"))
    end
  end

  describe "Alert Settings and Pause Alerts" do
    it "defaults the usual route on (usual timing, Mon to Fri, 5 min), saves per timing, checks the HTML's messages, and lists every route" do
      r = rider
      get "#{base(r)}/routes/#{f[:trip].id}/alerts", headers: r[:h]
      expect(json.dig(:data, :setting)).to include(enabled: false, saved: false, run_ids: [], weekdays: [ 1, 2, 3, 4, 5 ], lead_minutes: 5)
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am1].id }, headers: r[:h], as: :json
      get "#{base(r)}/routes/#{f[:trip].id}/alerts", headers: r[:h]
      expect(json.dig(:data, :setting)).to include(enabled: true, saved: false, run_ids: [ f[:am1].id ])
      expect(json.dig(:data, :timings).pluck(:run_id, :direction, :time)).to eq([ [ f[:am1].id, 1, "07:30" ], [ f[:am2].id, 1, "08:30" ], [ f[:pm].id, 2, "18:00" ] ])

      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { enabled: true, run_ids: [ f[:am2].id, f[:pm].id ], weekdays: [ 1, 3 ], lead_minutes: 10, late: false, notices: false }, headers: r[:h], as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json.dig(:data, :setting)).to include(enabled: true, saved: true, run_ids: contain_exactly(f[:am2].id, f[:pm].id), weekdays: [ 1, 3 ], lead_minutes: 10,
                                                  notify: { bus_change: true, service_days: true, late: false, notices: false })
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { run_ids: [ f[:am1].id ] }, headers: r[:h], as: :json # one timing replaced, the rest kept
      expect(json.dig(:data, :setting)).to include(run_ids: [ f[:am1].id ], weekdays: [ 1, 3 ], lead_minutes: 10)

      get "/api/v1/app/shuttles/alerts", headers: r[:h]
      expect(json.dig(:data, :routes)).to contain_exactly(a_hash_including(route: { id: f[:trip].id, name: "MBC Campus Shuttle" }, enabled: true, timings: 1, saved: true))
    end

    it "refuses on without a timing or a change, timings without a day, a lead other than 5 / 10 / 15, and a timing of another route" do
      r = rider
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { enabled: true, run_ids: [], bus_change: false, service_days: false, late: false, notices: false }, headers: r[:h], as: :json
      expect(json.dig(:error, :message)).to eq("Pick a timing to be reminded for, or a change to hear about, or turn alerts off")
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { enabled: true, run_ids: [ f[:am1].id ], weekdays: [] }, headers: r[:h], as: :json
      expect(json.dig(:error, :message)).to eq("Pick at least one day")
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { run_ids: [ f[:am1].id ], lead_minutes: 7 }, headers: r[:h], as: :json
      expect(response).to have_http_status(:unprocessable_content)
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { run_ids: [ 999_999 ] }, headers: r[:h], as: :json
      expect(json.dig(:error, :message)).to eq("Pick a timing of this route")
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { enabled: false, run_ids: [] }, headers: r[:h], as: :json # off is always allowed
      expect(response).to have_http_status(:ok)
    end

    it "pauses until a date after today, resumes, and lets the date pass" do
      r = rider
      put "/api/v1/app/shuttles/pause", params: { until: today.iso8601 }, headers: r[:h], as: :json
      expect(json.dig(:error, :message)).to eq("Pick a date after today")
      put "/api/v1/app/shuttles/pause", params: { until: "2026-12-01" }, headers: r[:h], as: :json
      expect(json[:data]).to eq(paused_until: "2026-12-01")
      get "/api/v1/app/shuttles/alerts", headers: r[:h]
      expect(json.dig(:data, :paused_until)).to eq("2026-12-01")
      delete "/api/v1/app/shuttles/pause", headers: r[:h]
      expect(json[:data]).to eq(paused_until: nil)
      expect(r[:account].reload.shuttle_alerts_paused_until).to be_nil
    end
  end

  describe "the alert job" do
    let(:r) { rider }
    # Shuttle alerts only (the employer invite alert of Phase 8 is in the same inbox).
    let(:shuttle_kinds) { %w[shuttle_bus_change shuttle_cancelled shuttle_service_day] }
    let(:inbox) { -> { AppNotification.where(app_account_id: r[:account].id, kind: shuttle_kinds).order(:id).pluck(:kind, :title, :body) } }

    before do
      put "#{base(r)}/usual", params: { trip_id: f[:trip].id, run_id: f[:am1].id, stop_id: f[:alexandra].id }, headers: r[:h], as: :json
      within_tenant(company) { Replacements::Save.call(replacement: Replacement.new, attributes: { kind: "veh", vehicle_id: f[:spare].id }, user: f[:admin], occurrence: occurrence(f[:am1], tomorrow, 1)) }
    end

    it "alerts 1 hour before the bus reaches the rider's stop, once, and again at once if the bus changes again" do
      travel_to Time.zone.local(2026, 11, 17, 6, 35)
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count) # 07:40 − 1 h = 06:40
      travel_to Time.zone.local(2026, 11, 17, 6, 41)
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(1)
      expect(inbox.call).to eq([ [ "shuttle_bus_change", "Different bus", "Look for PD5126A on the 07:30 MBC Campus Shuttle shuttle today instead of PC8841T. It reaches Alexandra Road at 07:40." ] ])
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(0)

      within_tenant(company) { Replacements::Save.call(replacement: Replacement.new, attributes: { kind: "veh", vehicle_id: f[:bus2].id }, user: f[:admin], occurrence: occurrence(f[:am1], tomorrow, 1)) }
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(1)
      expect(inbox.call.last[2]).to include("Look for PD4472H")
      get "#{base(r)}/routes/#{f[:trip].id}", params: { date: tomorrow.iso8601 }, headers: r[:h]
      expect(json.dig(:data, :timing, :buses, 0, :change, :alert, :alerted_at)).to be_present
    end

    it "alerts at once when the change is made less than an hour before" do
      travel_to Time.zone.local(2026, 11, 17, 7, 20)
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(1)
    end

    it "sends nothing for a relief driver alone, an unticked timing or weekday, alerts off, Pause Alerts, a paused or removed link, or a No Fixed Bus route" do
      within_tenant(company) { Replacements::Save.call(replacement: Replacement.new, attributes: { kind: "drv", driver_id: f[:driver].id }, user: f[:admin], occurrence: occurrence(f[:am1], tomorrow, 2)) }
      travel_to Time.zone.local(2026, 11, 17, 7, 20)
      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { run_ids: [ f[:am2].id ] }, headers: r[:h], as: :json # the changed 07:30 is not ticked
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)

      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { run_ids: [ f[:am1].id ], weekdays: [ 1 ] }, headers: r[:h], as: :json # Tuesday not ticked
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)

      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { run_ids: [ f[:am1].id ], weekdays: [ 2 ], enabled: false }, headers: r[:h], as: :json
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)

      put "#{base(r)}/routes/#{f[:trip].id}/alerts", params: { enabled: true }, headers: r[:h], as: :json
      put "/api/v1/app/shuttles/pause", params: { until: "2026-12-01" }, headers: r[:h], as: :json
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)
      delete "/api/v1/app/shuttles/pause", headers: r[:h]

      within_tenant(company) { f[:trip].update_columns(no_fixed_bus: true) } # rubocop:disable Rails/SkipsModelValidations
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)
      within_tenant(company) { f[:trip].update_columns(no_fixed_bus: false) } # rubocop:disable Rails/SkipsModelValidations

      ActsAsTenant.without_tenant { r[:link].update!(status: "removed") }
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)
      ActsAsTenant.without_tenant { r[:link].update!(status: "accepted") }
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(1) # everything back on: the bus change comes
    end

    it "tells a cancelled run at once, with the next bus, and nothing about a run that has ended" do
      within_tenant(company) { [ 1, 2 ].each { |slot| Occurrences::Edit.new(occurrence(f[:am1], tomorrow, slot), f[:admin]).cancel! } }
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(1)
      expect(inbox.call.last).to eq([ "shuttle_cancelled", "Shuttle cancelled", "MBC Campus Shuttle 07:30 on tomorrow was cancelled by SimpleDrive. Next bus 08:30 from Labrador Park MRT." ])
      travel_to Time.zone.local(2026, 11, 17, 9, 0)
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(0)
    end

    it "tells a day with no service the day before at 12:00, once" do
      within_tenant(company) { PublicHoliday.create!(company:, date: today + 3, name: "Deepavali") && Occurrences::Sync.call(trips: [ f[:trip] ]) }
      travel_to Time.zone.local(2026, 11, 18, 11, 59)
      expect { ConvoyApp::Shuttles::Alerts.call }.not_to change(AppNotification, :count)
      travel_to Time.zone.local(2026, 11, 18, 12, 0)
      expect(ConvoyApp::Shuttles::Alerts.call).to be >= 1
      expect(AppNotification.where(kind: "shuttle_service_day").pluck(:title)).to eq([ "No service tomorrow" ])
      expect(ConvoyApp::Shuttles::Alerts.call).to eq(0)
    end

    it "keeps each person's inbox apart" do
      other = rider(mobile: "9177 3301", email: "david@google.com")
      travel_to Time.zone.local(2026, 11, 17, 7, 20)
      ConvoyApp::Shuttles::Alerts.call
      expect(AppNotification.where(app_account_id: other[:account].id, kind: shuttle_kinds)).to be_empty # David has no usual and alerts off by default
      expect(AppNotification.where(app_account_id: r[:account].id, kind: shuttle_kinds).count).to eq(1)
    end
  end
end
