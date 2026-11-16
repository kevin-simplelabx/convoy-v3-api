require "rails_helper"

# Convoy App Phase 8: Live Tracking (the 10-minute window, only the child's stop named, never another child), the alert
# writers (boarded / alighted, trip started, 10 min away, running late, different bus, school notice, request status, bill),
# the Alerts inbox (filter, read, Mark All Read, one inbox per account), Home (banners + dismiss, Up Next, tiles and badges,
# Get Started) and Activity.
RSpec.describe "Convoy App home, alerts and live tracking" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:day) { Date.new(2026, 11, 3) }
  let!(:f) do
    within_tenant(company) do
      bus = create(:vehicle, plate: "SBA3546K", seats: 40, make: "Yutong", model: "ZK6107")
      spare = create(:vehicle, plate: "PC7475L", seats: 40)
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", lat: 1.3138, lng: 103.9283)
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-19")
      %w[E-1 K-9].each { school.riders.create!(rid: it, name: it == "E-1" ? "Ethan Tan" : "Kara Lim", grade: "P4", postal: "460412", am: true, pm: true, source: "manual") }
      am = school.plans.create!(name: "AM", session: "am", effective_from: Date.new(2026, 10, 1), in_use: true)
      route = am.routes.create!(number: 1, label: "AM 1", start_time: "07:00", end_time: "07:40", bus_type: "LARGE_40", seats: 40)
      stops = [ [ "Blk 11 Chai Chee", "07:00", 1.3270, 103.9230 ], [ "Blk 22 Bedok", "07:08", 1.3290, 103.9260 ],
                [ "Blk 412 Bedok North", "07:20", 1.3236, 103.9300 ], [ "Blk 99 Tampines", "07:28", 1.3400, 103.9500 ] ]
                .each_with_index.map { |(n, t, lat, lng), i| route.stops.create!(position: i, name: n, scheduled_time: t, lat:, lng:) }
      SchoolRouteRider.create!(school_route: route, stop: stops[2], rid: "E-1")
      SchoolRouteRider.create!(school_route: route, stop: stops[0], rid: "K-9")
      route.vehicle_changes.create!(vehicle: bus, effective_from: Date.new(2026, 10, 1))
      { school:, route:, stops:, bus:, spare: }
    end
  end
  let!(:rachel) { app_user(mobile: "9188 2045", name: %w[Rachel Tan]) }
  let!(:david) { app_user(mobile: "9177 3301", name: %w[David Tan]) }
  let!(:home) do
    h = Household.create!(name: "Tan Family", postal: "460412", block: "412", street: "Bedok North Ave 2", lat: 1.3236, lng: 103.93, created_by: rachel[0])
    h.members.create!(app_account: rachel[0], status: :active, admin: true, billing_contact: true, relationship: "Mother", invited_via: :creator, joined_at: 1.day.ago)
    h.members.create!(app_account: david[0], status: :active, relationship: "Father", invited_via: :manual, joined_at: 1.day.ago)
    h
  end
  let!(:ethan) { home.dependants.create!(name: "Ethan Tan", birth_date: "2017-03-14", level: "P4", school_id: f[:school].id, school_name: "St. Stephen's School") }
  let!(:family) do
    within_tenant(company) do
      fam = Family.create!(school: f[:school], household: home, code: "FAM-0001", name: "Tan Family")
      FamilyRider.create!(family: fam, school: f[:school], rid: "E-1", dependant: ethan)
      fam
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 3, 5, 0)
    within_tenant(company) { Occurrences::Sync.call(routes: [ f[:route] ]) }
  end

  def occ = within_tenant(company) { TripOccurrence.find_by!(school_route_id: f[:route].id, date: day) }
  def api(path, token: rachel[1], **params) = get(path, params:, headers: app_as(token))
  def sweep = ConvoyApp::Alerts::Sweep.call
  def alerts(account) = account.notifications.order(:id)

  # The driver starts at 07:00 and has left the first two stops.
  def drive!(late: 0, position: [ 1.3290, 103.9260 ])
    within_tenant(company) do
      o = occ
      o.update!(started_at: day.in_time_zone.change(hour: 6, min: 55))
      [ 0, 1 ].each do |i|
        at = day.in_time_zone.change(hour: 7, min: i * 8) + late.minutes
        o.stop_events.create!(company_id: company.id, position: i, arrived_at: at, departed_at: at + 1.minute)
      end
      VehicleLivePosition.create!(vehicle: f[:bus], lat: position[0], lng: position[1], speed_kmh: 30, heading: 90, recorded_at: Time.current)
    end
  end

  describe "Live Tracking" do
    it "waits with the ETA and crew, names only the child's stop, and shows no bus until 10 minutes before it" do
      travel_to Time.zone.local(2026, 11, 3, 6, 40)
      api(live_api_v1_convoy_app_school_path)
      d = json[:data]
      expect(d[:state]).to eq("far")
      expect(d[:buses]).to eq([ { key: "#{f[:route].id}-2026-11-03", date: "2026-11-03", names: [ "Ethan Tan" ], first_names: [ "Ethan" ], plate: "SBA3546K", warn: false } ])
      b = d[:bus]
      expect(b).to include(title: "SSS AM 1", sub: "SBA3546K · SSS AM 1 · Pick-up", status: { label: "Scheduled", tone: "neutral" }, position: nil, path: nil)
      expect(b[:riders]).to eq([ { dependant_id: ethan.id, name: "Ethan Tan", first_name: "Ethan" } ])
      expect(b[:stops].pluck(:name, :meta)).to eq([ [ "Stop 1", nil ], [ "Stop 2", nil ], [ "Blk 412 Bedok North", "Ethan boards here" ], [ "St. Stephen's School", "Arrive" ] ])
      expect(b[:eta]).to include(label: "ETA at Blk 412 Bedok North", at: "07:20", scheduled: "07:20", stops_away: 2)
      expect(b[:my_stop]).to include(name: "Blk 412 Bedok North", lat: 1.3236)
      # Privacy: no other child, no other stop's name or place anywhere in the answer
      body = response.body
      expect(body).not_to include("Kara", "K-9", "Chai Chee", "Blk 22", "Tampines", "103.923")
    end

    it "opens the map 10 minutes before the child's stop: position and the line ahead, never other stops" do
      drive!
      travel_to Time.zone.local(2026, 11, 3, 7, 5)
      api(live_api_v1_convoy_app_school_path)
      expect(json.dig(:data, :state)).to eq("far") # bus at Blk 22 (planned 07:08), Ethan's stop at 07:20: 15 min away

      travel_to Time.zone.local(2026, 11, 3, 7, 11)
      api(live_api_v1_convoy_app_school_path)
      b = json.dig(:data, :bus)
      expect(json.dig(:data, :state)).to eq("near")
      expect(b[:status]).to eq(label: "Started", tone: "warning")
      expect(b[:position]).to include(lat: 1.329, lng: 103.926)
      expect(b[:path]).to eq([ [ 1.329, 103.926 ], [ 1.3236, 103.93 ], [ 1.3138, 103.9283 ] ])
      expect(b[:stops].pluck(:state)).to eq(%w[departed departed next upcoming])
      expect(b[:crew]).to eq([])
      expect(response.body).not_to include("Chai Chee", "Kara")
    end

    it "says when the bus or driver is not the usual one" do
      within_tenant(company) { occ.update_columns(vehicle_id: f[:spare].id) } # rubocop:disable Rails/SkipsModelValidations
      travel_to Time.zone.local(2026, 11, 3, 6, 40)
      api(live_api_v1_convoy_app_school_path)
      expect(json.dig(:data, :bus, :change)).to eq(title: "Not the usual bus or crew",
                                                   text: "Today a different bus, PC7475L instead of SBA3546K. Pick-up time is the same.")
      expect(json.dig(:data, :buses, 0, :warn)).to be(true)
    end

    it "has nothing to track for a Family without a riding child, and needs a Family" do
      other = app_user(mobile: "9166 7720", name: %w[Priya Nair])
      api(live_api_v1_convoy_app_school_path, token: other[1])
      expect(response).to have_http_status(:not_found)
      expect(json.dig(:error, :code)).to eq("no_household")

      h = Household.create!(name: "Nair Family", postal: "460412", block: "1", street: "Bedok", created_by: other[0])
      h.members.create!(app_account: other[0], status: :active, admin: true, billing_contact: true, invited_via: :creator, joined_at: 1.day.ago)
      api(live_api_v1_convoy_app_school_path, token: other[1])
      expect(json[:data]).to include(state: "none", buses: [], bus: nil)
    end
  end

  describe "alert writers" do
    it "tells every adult of the Family when the child boards and alights, never about another child" do
      within_tenant(company) do
        Occurrences::MarkPassengers.call(occ:, marks: [ { key: "E-1", state: "boarded" }, { key: "K-9", state: "boarded" } ], by: "Driver", source: "driver_app")
        Occurrences::MarkPassengers.call(occ:, marks: [ { key: "E-1", state: "boarded" } ], by: "Driver", source: "driver_app") # again: no repeat
        Occurrences::MarkPassengers.call(occ:, marks: [ { key: "E-1", state: "alighted" } ], by: "Driver", source: "driver_app")
      end
      [ rachel[0], david[0] ].each do |acc|
        expect(alerts(acc).pluck(:kind, :title, :body)).to eq([
          [ "school_boarded", "Ethan Tan boarded", "Boarded Bus SBA3546K at Blk 412 Bedok North." ],
          [ "school_alighted", "Ethan Tan alighted", "Arrived at St. Stephen's School." ]
        ])
      end
      expect(alerts(rachel[0]).first).to have_attributes(target: "live", target_id: ethan.id, dependant_id: ethan.id, company_id: company.id)
      expect(AppNotification.count).to eq(4)
    end

    it "writes trip started, running late in 5-minute steps, and 10 minutes away from the job, once each" do
      drive!(late: 6)
      travel_to Time.zone.local(2026, 11, 3, 7, 10)
      sweep
      expect(alerts(rachel[0]).pluck(:kind, :title)).to contain_exactly(
        [ "school_started", "Morning trip started" ], [ "school_late", "Bus SBA3546K running 6 min late" ]
      )
      late = alerts(rachel[0]).find_by(kind: "school_late")
      expect(late.body).to eq("New pick-up ETA 07:26 at Blk 412 Bedok North.")
      expect(late.banner_until).to eq(occ.ends_at)
      expect { sweep }.not_to change(AppNotification, :count)

      travel_to Time.zone.local(2026, 11, 3, 7, 17)
      sweep
      expect(alerts(rachel[0]).where(kind: "school_near").sole).to have_attributes(title: "Bus SBA3546K is 9 min from Blk 412 Bedok North", target: "live")
      expect(alerts(david[0]).where(kind: "school_started").count).to eq(1)
    end

    it "warns of a different bus from 1 hour before the child's stop, not for a child marked Bus Not Required" do
      within_tenant(company) { occ.update_columns(vehicle_id: f[:spare].id) } # rubocop:disable Rails/SkipsModelValidations
      travel_to Time.zone.local(2026, 11, 3, 6, 10)
      sweep
      expect(AppNotification.count).to eq(0)
      travel_to Time.zone.local(2026, 11, 3, 6, 21)
      sweep
      expect(alerts(rachel[0]).sole).to have_attributes(kind: "school_bus_change", title: "Different bus for Ethan today",
                                                        body: "Today PC7475L instead of SBA3546K. Pick-up time is the same.")

      AppNotification.delete_all
      within_tenant(company) { SchoolRiderAbsence.create!(school: f[:school], rid: "E-1", date: day, trip: "both", reason: "sick") }
      sweep
      expect(AppNotification.count).to eq(0)
    end

    it "copies a school notice to the Family once, keeps it on Home until it ends, and drops it from Home when dismissed" do
      notice = within_tenant(company) do
        Notice.create!(audience: "school", school: f[:school], to_parents: true, to_riders: false, message: "Early dismissal on Wed 4 Nov. School ends 11:30.",
                       starts_at: Time.current, ends_at: 2.days.from_now)
      end
      sweep
      sweep
      a = alerts(rachel[0]).sole
      expect(a).to have_attributes(kind: "school_notice", title: "Notice from SimpleDrive", notice_id: notice.id, banner_until: notice.ends_at)
      expect(notice.reload.app_sent_at).to be_present

      api(api_v1_convoy_app_home_path)
      expect(json.dig(:data, :banners).sole).to include(id: a.id, kind: "school_notice", sender: "SimpleDrive", body: notice.message)
      post api_v1_convoy_app_home_banner_dismiss_path(a.id), headers: app_as(rachel[1])
      api(api_v1_convoy_app_home_path)
      expect(json.dig(:data, :banners)).to eq([])
      api(api_v1_convoy_app_home_path, token: david[1]) # David still sees his own
      expect(json.dig(:data, :banners).size).to eq(1)

      ConvoyApp::Alerts.notice_ended(notice)
      api(api_v1_convoy_app_home_path, token: david[1])
      expect(json.dig(:data, :banners)).to eq([])
      expect(alerts(david[0]).count).to eq(1) # still in the inbox
    end

    it "tells the other adults when a request changes status, and the Billing Contact only about a bill" do
      within_tenant(company) do
        req = BusRequest.create!(school: f[:school], kind: "new", source: "app", status: "Requested", child_name: "Ethan Tan", household_id: home.id,
                                 dependant_id: ethan.id, submitted_at: Time.current)
        expect(AppNotification.count).to eq(0)
        Audited.audit_class.as_user(rachel[0]) { req.update!(status: "Withdrawn") } # Rachel did it herself
        expect(alerts(rachel[0])).to be_empty
        expect(alerts(david[0]).sole).to have_attributes(kind: "request_update", target: "school_request", target_id: req.id, title: start_with("Ethan Tan ·"))

        bill = SchoolBill.create!(school: f[:school], family:, payer: "family", kind: "period", status: "issued", number: "INV-2026-0901", issued_on: day,
                                  subtotal: 600, total: 600, due_on: Date.new(2026, 11, 17), period_label: "Term 4")
        ConvoyApp::Alerts::Bills.call([ bill ])
        expect(alerts(rachel[0]).sole).to have_attributes(kind: "bill_issued", title: "Invoice INV-2026-0901 issued", body: "Term 4 · S$600.00 · due 17 Nov.",
                                                          target: "fee_invoice", target_id: bill.id)
        expect(alerts(david[0]).where(kind: "bill_issued")).to be_empty
      end
    end
  end

  describe "Alerts inbox" do
    before do
      rows = [ [ "school_late", "Bus late" ], [ "school_notice", "Notice" ], [ "school_boarded", "Boarded" ] ]
      rows.each_with_index { |(kind, title), i| rachel[0].notifications.create!(kind:, title:, body: "x", dedupe_key: "t#{i}", created_at: Time.current - i.days) }
      david[0].notifications.create!(kind: "school_late", title: "David's", body: "x", dedupe_key: "d")
    end

    it "lists the person's own alerts newest first, filters Delays / Notices, reads one and all" do
      api(api_v1_convoy_app_alerts_path)
      expect(json[:data].pluck(:title, :group, :read)).to eq([ [ "Bus late", "today", false ], [ "Notice", "earlier", false ], [ "Boarded", "earlier", false ] ])
      expect(json[:data].first).to include(icon: "schedule", tone: "warning", filter: "delays", chip: "track_bus")
      expect(json[:meta]).to include(count: 3, unread: 3, filter: "all")
      api(api_v1_convoy_app_alerts_path, filter: "delays")
      expect(json[:data].pluck(:title)).to eq([ "Bus late" ])
      api(api_v1_convoy_app_alerts_path, filter: "notices")
      expect(json[:data].pluck(:title)).to eq([ "Notice" ])

      id = rachel[0].notifications.find_by(title: "Notice").id
      post api_v1_convoy_app_alert_read_path(id), headers: app_as(rachel[1])
      expect(json[:data][:read]).to be(true)
      expect(json[:meta]).to eq(unread: 2)
      api(api_v1_convoy_app_home_path)
      expect(json.dig(:data, :badges)).to eq(alerts: 2)

      post api_v1_convoy_app_alerts_read_all_path, headers: app_as(rachel[1])
      expect(json[:data]).to eq(updated: 2, unread: 0)
      expect(david[0].notifications.unread.count).to eq(1)
    end

    it "never reads or dismisses another person's alert" do
      id = david[0].notifications.sole.id
      post api_v1_convoy_app_alert_read_path(id), headers: app_as(rachel[1])
      expect(response).to have_http_status(:not_found)
      post api_v1_convoy_app_home_banner_dismiss_path(id), headers: app_as(rachel[1])
      expect(response).to have_http_status(:not_found)
      get api_v1_convoy_app_alerts_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "Home and Activity" do
    it "shows the morning bus in Up Next, the tiles with the due-bill badge for the Billing Contact only" do
      within_tenant(company) do
        SchoolBill.create!(school: f[:school], family:, payer: "family", kind: "period", status: "issued", number: "INV-1", issued_on: day, subtotal: 600,
                           total: 600, due_on: day + 14)
      end
      travel_to Time.zone.local(2026, 11, 3, 6, 40)
      api(api_v1_convoy_app_home_path)
      d = json[:data]
      expect(d[:greeting]).to eq(first_name: "Rachel", part_of_day: "morning", text: "Good morning, Rachel")
      expect(d[:up_next].sole).to include(kind: "school_bus", label: "School Bus · SimpleDrive · SSS AM 1", badge: "Scheduled",
                                          depart: { time: "07:20", text: "Pick-up · Blk 412 Bedok North" }, foot: "Ethan · SBA3546K",
                                          open: { kind: "live", bus: "#{f[:route].id}-2026-11-03" })
      expect(d[:tiles].map { it.slice(:key, :caption, :badge) }).to eq([
        { key: "school_bus", caption: "1 child", badge: 1 }, { key: "shuttles", caption: "By employer", badge: nil },
        { key: "bookings", caption: "Book a bus", badge: nil }, { key: "discover", caption: "Coming soon", badge: nil }
      ])
      expect(d[:get_started]).to be(false)
      api(api_v1_convoy_app_home_path, token: david[1])
      expect(json.dig(:data, :tiles, 0, :badge)).to be_nil
    end

    it "offers Get Started to a person with nothing yet and lists a Family invite to answer" do
      newbie = app_user(mobile: "8123 4567", name: %w[Mei Tan])
      home.members.create!(app_account: newbie[0], status: :invited, relationship: "Relative", invited_via: :manual, invited_by: rachel[0])
      api(api_v1_convoy_app_home_path, token: newbie[1])
      d = json[:data]
      expect(d).to include(get_started: true, up_next: [])
      expect(d[:greeting][:text]).to eq("Welcome, Mei")
      expect(d.dig(:invitations, :family)).to contain_exactly(a_hash_including(family: "Tan Family", invited_by: "Rachel Tan", relationship: "Relative"))
    end

    it "lists the child's legs under Now, Upcoming and Past" do
      drive!
      travel_to Time.zone.local(2026, 11, 3, 7, 12)
      api(api_v1_convoy_app_activity_path)
      d = json[:data]
      expect(d[:services]).to eq([ "school" ])
      expect(d[:now].sole).to include(service: "school", date: "2026-11-03", time: "07:20", title: "Pick-up · Ethan", sub: "Blk 412 Bedok North · SBA3546K",
                                      badge: "Started", live: true, open: { kind: "live", bus: "#{f[:route].id}-2026-11-03" })
      expect(d[:upcoming].first).to include(date: "2026-11-04", badge: "Scheduled", open: { kind: "bus_info", dependant_id: ethan.id, session: "am" })
      api(api_v1_convoy_app_activity_path, service: "booking")
      expect(json[:data]).to include(service: "booking", now: [], upcoming: [], past: [])
    end
  end
end
