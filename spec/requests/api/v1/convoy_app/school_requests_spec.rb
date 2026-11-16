require "rails_helper"

# Convoy App › School Bus (4a): the apply form, Review and Estimated Fare from the real Bus Fares, Submit with the
# registration fee bill, Application Status (Billing Contact sees the money), Withdraw, OS Accept linking the Family into
# the company's families, the School page and Bus Information, Renew / Change Service / Stop, Change of Address with
# Agree to New Fare moving the Family's home, the Delete Family hook, and that one Family never reaches another's data.
RSpec.describe "Convoy App school bus requests" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:staff) { create(:user, company:, permissions: %w[plans]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", postal: "455789", lat: 1.3138, lng: 103.9283)
      %w[P1 P2 P3 P4 P5 P6].each_with_index { |n, i| school.levels.create!(name: n, position: i, final: n == "P6") }
      year = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      year.terms.first.update!(starts_on: "2027-01-04", ends_on: "2027-05-28")
      year.terms.second.update!(starts_on: "2027-06-28", ends_on: "2027-11-19")
      SchoolSetup.lock!(school:, year:, section: :calendar, user: staff)
      FareTables::Save.call(year, { payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal",
                                    one_way: { type: "pct", value: 60 }, tiers: [ { max_km: 3, fare: 1680 }, { max_km: 6, fare: 1920 }, { fare: 2400 } ],
                                    small: { on: false }, express: { on: false }, cca: { on: false } }, user: staff)
      year.create_registration!(school:, status: "scheduled", renew_from: "2026-10-01", renew_to: "2026-10-31", general_from: "2026-11-01",
                                general_to: "2027-08-31", service_starts_on: "2027-01-04")
      SchoolPolicyVersion.create!(school:, version: 1, effective_on: "2026-01-01", registration_fee: 50, address_notice_days: 14, address_max_days: 90)
      { school:, year: }
    end
  end
  let!(:rachel) { app_user(mobile: "9188 2045", name: %w[Rachel Tan]) }
  let!(:david) { app_user(mobile: "9177 3301", name: %w[David Tan]) }
  def token = @token || rachel[1]
  let!(:home) do
    h = Household.create!(name: "Tan Family", postal: "460412", block: "412", street: "Bedok North Ave 2", floor: "08", unit: "123", lat: 1.3236, lng: 103.93,
                          created_by: rachel[0])
    h.members.create!(app_account: rachel[0], status: :active, admin: true, billing_contact: true, relationship: "Mother", invited_via: :creator, joined_at: 1.day.ago)
    h.members.create!(app_account: david[0], status: :active, relationship: "Father", invited_via: :manual, joined_at: 1.day.ago)
    h
  end
  let!(:ethan) { home.dependants.create!(name: "Ethan Tan", birth_date: "2017-03-14", level: "P4", school_id: f[:school].id, school_name: "St. Stephen's School") }
  let!(:lucas) { home.dependants.create!(name: "Lucas Tan", birth_date: "2020-08-02", level: "P1", school_id: f[:school].id, school_name: "St. Stephen's School") }

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  # GET sends params in the query (Rails turns a GET `as: :json` with params into a POST with a method override).
  def api(verb, path, token: self.token, **params)
    return get(path, params:, headers: app_as(token)) if verb == :get

    public_send(verb, path, params:, headers: app_as(token), as: :json)
  end

  def child(dep, **over) = { dependant_id: dep.id, level: "P5", service: "both", start_when: "first" }.merge(over)

  def apply(*kids, agree: true, token: self.token)
    api(:post, apply_api_v1_convoy_app_school_path, token:, application: { school_id: f[:school].id, agree:, children: kids })
  end

  def tenant(&) = within_tenant(company, &)

  # Travel, then sign in again (tokens expire); David too.
  def later(time)
    travel_to time
    @token = app_token(mobile: "9188 2045")
    @david = app_token(mobile: "9177 3301")
  end

  def david_token = @david || david[1]

  it "shows the form, reviews the real fare and sends one request per child with one registration fee bill" do
    api(:get, apply_api_v1_convoy_app_school_path, school_id: f[:school].id)
    p = json.dig(:data, :providers).sole
    expect(p).to include(school_id: f[:school].id, year: "2027", show_fare: true, registration_fee: "50.0", levels: %w[P1 P2 P3 P4 P5 P6])
    expect(p[:company]).to include(name: "SimpleDrive", mark: "SD")
    expect(p[:window]).to include(state: "open", closes_on: "2027-08-31", starts_on: "2027-01-04")
    expect(p[:start]).to include(options: %w[first pref fixed], default: "first", first_day: "2027-01-04")
    expect(p[:children].map { it.slice(:name, :can_apply) }).to eq([ { name: "Ethan Tan", can_apply: true }, { name: "Lucas Tan", can_apply: true } ])

    api(:post, apply_review_api_v1_convoy_app_school_path, application: { school_id: f[:school].id, children: [ child(ethan), child(lucas, service: "am") ] })
    r = json[:data]
    expect(r[:children].first[:estimate]).to include(amount: "840.0", unit: "semester", km: "1.1")
    expect(r[:children].first[:estimate][:text]).to eq("About 1.1 km from school · two ways S$840.00 a semester")
    expect(r[:children].second[:estimate]).to include(amount: "504.0")
    expect(r).to include(riders: 2, total: "1344.0", registration_fee: { each: "50.0", total: "100.0" })
    expect(r[:children].first[:start]).to include(start_when: "first", start_on: "2027-01-04")

    apply(child(ethan), child(lucas), agree: false)
    expect(json.dig(:error, :message)).to eq("Agree to the Transport Procedures and Safety Rules to continue")

    other = { point: "other", postal: "460216", address: "Blk 216 Bedok North St 1" }
    apply(child(ethan, dropoff: other), child(lucas, service: "am", student_id: "S1-0099"))
    expect(response).to have_http_status(:created)
    list = json[:data]
    expect(list.map { it[:badge] }).to all(eq(label: "Fee Unpaid", tone: "warning"))
    expect(list.first).to include(status: "Requested", service: "both", year: "2027", can: hash_including(withdraw: true, pay_registration: true))
    expect(list.first[:dropoff]).to eq(address: "Blk 216 Bedok North St 1", postal: "460216")
    expect(list.first[:pickup]).to eq(address: "Blk 412 Bedok North Ave 2, #08-123", postal: "460412")
    expect(list.first[:registration_fee]).to include(paid: false, amount: "50.0")
    expect(list.first[:timeline].map { it[:state] }).to eq(%w[done current todo todo])
    expect(list.first[:timeline].first[:meta]).to eq("Submitted 2 Nov 2026 · registration fee unpaid")

    req, req2 = tenant { BusRequest.order(:id).to_a }
    expect(req).to have_attributes(source: "app", household_id: home.id, dependant_id: ethan.id, app_account_id: rachel[0].id, fee_paid: false,
                                   parent_name: "Rachel Tan", parent_phone: "+6591882045", estimate: 840, km: 1.1, start_when: "first",
                                   dropoff_postal: "460216", terms_agreed_at: be_present)
    expect(req2).to have_attributes(am: true, pm: false, student_no: "S1-0099", dropoff_address: nil)
    bill = tenant { req.registration_bill }
    expect(bill).to have_attributes(kind: "registration", status: "issued", total: 100, number: "INV-2026-000001", period_label: "Registration · AY2027")
    expect(tenant { bill.lines.map(&:description) }).to eq([ "Ethan Tan | Registration fee · St. Stephen's School", "Lucas Tan | Registration fee · St. Stephen's School" ])
    expect(tenant { req.events.first.text }).to eq("Sent from the Convoy App by Rachel Tan. Registration fee S$50.00 invoiced (INV-2026-000001)")

    # David (not the Billing Contact) sees the request and that the fee is unpaid, never the bill or its amount
    api(:get, api_v1_convoy_app_school_request_path(req), token: david_token)
    expect(json[:data][:registration_fee]).to eq(paid: false, amount: nil, bill: nil)
    expect(json[:data][:can]).to include(pay_registration: false)

    # The badge reaches the Household and the School page
    api(:get, api_v1_convoy_app_household_path)
    expect(json.dig(:data, :children).map { it[:status][:label] }).to eq([ "Fee Unpaid", "Fee Unpaid" ])
    api(:get, api_v1_convoy_app_school_path)
    card = json.dig(:data, :children).first
    expect(card[:line]).to eq("Requested 2 Nov 2026 for AY2027, est. S$840.00 a month. SimpleDrive replies within 1 to 2 weeks")
    expect(card[:action]).to include(kind: "pay_registration", bill_id: bill.id)

    # The same child cannot apply twice; paying the fee in Convoy OS marks it paid
    apply(child(ethan))
    expect(json.dig(:error, :message)).to eq("Ethan already has a bus request for 2027")
    tenant { SchoolBills::RecordPayment.call(f[:school], [ [ bill, 100 ] ], paid_on: Date.current, method: "PayNow", user: staff) }
    expect(tenant { req.reload.fee_paid }).to be(true)
    api(:get, api_v1_convoy_app_school_request_path(req))
    expect(json[:data][:badge]).to eq(label: "Requested", tone: "info")
  end

  it "checks each child as the form does" do
    apply(child(ethan, level: ""))
    expect(json.dig(:error, :message)).to eq("Choose the level")
    apply(child(ethan, pickup: { point: "other", postal: "12", address: "x" }))
    expect(json.dig(:error, :message)).to eq("Enter the pick-up postal code and address")
    apply(child(ethan, start_when: "fixed", start_on: "2026-12-01"))
    expect(json.dig(:error, :message)).to eq("Pick a date from the first school day, 4 Jan 2027")
    apply(child(ethan, start_when: "fixed", start_on: "2027-02-01", fix_why: "other"))
    expect(json.dig(:error, :message)).to eq("Say why the bus has to start on this date")
    apply(child(ethan, start_when: "pref", start_on: "2028-02-01"))
    expect(json.dig(:error, :message)).to eq("Pick a date in the 2027 school year, up to 31 Dec 2027. Requests for a later year open with its registration")

    later(Time.zone.local(2027, 9, 1, 9, 0))
    apply(child(ethan))
    expect(json.dig(:error, :message)).to eq("Bus requests for St. Stephen's School closed on 31 Aug 2027")
  end

  it "keeps one Family away from another's children and requests" do
    apply(child(ethan))
    mine = json[:data].first[:id]
    other_token = app_user(mobile: "9650 1187", name: %w[Mei Lim])[1]
    other = Household.create!(name: "Lim Family", postal: "460101", block: "101", street: "Bedok North", created_by: AppAccount.last)
    other.members.create!(app_account: AppAccount.last, status: :active, admin: true, billing_contact: true, invited_via: :creator)

    api(:get, api_v1_convoy_app_school_request_path(mine), token: other_token)
    expect(response).to have_http_status(:not_found)
    api(:post, withdraw_api_v1_convoy_app_school_request_path(mine), token: other_token)
    expect(response).to have_http_status(:not_found)
    apply(child(lucas), token: other_token)
    expect(json.dig(:error, :message)).to eq("Choose a child from your Family")
    api(:get, api_v1_convoy_app_school_path, token: other_token)
    expect(json.dig(:data, :children)).to eq([])
    api(:get, rider_bus_api_v1_convoy_app_school_path(ethan.id), token: other_token)
    expect(response).to have_http_status(:not_found)
  end

  # Each check runs again on the rows as they are now (household / request lock): a second submission sent at the same
  # time, or a withdraw after the first invoice was paid, is refused; a deleted Family's open applications are withdrawn
  # so Convoy OS can't accept one for a child who no longer exists.
  it "sends a child's application once, withdraws only an open one, and withdraws open ones when the Family is deleted" do
    calls = 0
    allow_any_instance_of(ConvoyApp::Parents::Submit).to receive(:open_request?).and_wrap_original do |m, *args| # rubocop:disable RSpec/AnyInstance
      (calls += 1) == 1 ? false : m.call(*args) # the first check ran before the other submission was saved
    end
    apply(child(ethan))
    expect(response).to have_http_status(:created), json.inspect
    apply(child(ethan))
    expect(json.dig(:error, :message)).to eq("Ethan already has a bus request for 2027")
    expect(tenant { BusRequest.where(dependant_id: ethan.id).count }).to eq(1)

    stale = tenant { BusRequest.find_by!(dependant_id: ethan.id) }
    tenant { BusRequest.where(id: stale.id).update_all(status: "Active") } # rubocop:disable Rails/SkipsModelValidations -- paid meanwhile
    expect { tenant { ConvoyApp::Parents::Withdraw.call(stale, account: rachel[0]) } }
      .to raise_error(ApplicationService::Error, "This request can no longer be withdrawn")
    tenant { BusRequest.where(id: stale.id).update_all(status: "Requested") } # rubocop:disable Rails/SkipsModelValidations

    allow(ConvoyApp::Households::BusService).to receive(:delete_blockers).and_return([])
    api(:delete, api_v1_convoy_app_household_path)
    expect(response).to have_http_status(:ok), json.inspect
    req = tenant { BusRequest.find(stale.id) }
    expect(req.status).to eq("Withdrawn")
    expect(tenant { req.events.map(&:text) }).to include("Withdrawn: the Family was deleted in the Convoy App")

    tenant { BusRequest.where(id: stale.id).update_all(status: "Requested") } # rubocop:disable Rails/SkipsModelValidations -- as if left open
    sign_in_as(staff)
    post accept_api_v1_bus_request_path(stale.id), params: { amount: 840, start_on: "2027-01-04" }, as: :json
    expect(json.dig(:error, :message)).to eq("Ethan Tan's Family was deleted in the Convoy App. This request can't be accepted")
  end

  it "withdraws, and links the Family into the company's families when Convoy OS accepts" do
    apply(child(ethan), child(lucas))
    ids = json[:data].pluck(:id)
    api(:post, withdraw_api_v1_convoy_app_school_request_path(ids.second))
    expect(json[:data]).to include(status: "Withdrawn", can: hash_including(withdraw: false))

    sign_in_as(staff)
    get api_v1_bus_request_path(ids.first)
    expect(json[:data]).to include(app_family: true, source: "app", registration_bill: hash_including(paid: false), dropoff: nil)
    post accept_api_v1_bus_request_path(ids.first), params: { amount: 840, start_on: "2027-01-04" }, as: :json
    expect(json[:data]).to include(status: "Accepted")
    fam = tenant { Family.find_by!(household_id: home.id) }
    expect(fam).to have_attributes(name: "Tan Family", source: "app", school_id: f[:school].id, postal: "460412")
    expect(tenant { fam.guardians.map { [ it.name, it.relationship, it.household_member_id.present?, it.phone ] } })
      .to eq([ [ "Rachel Tan", "Mother", true, "+6591882045" ], [ "David Tan", "Father", true, "+6591773301" ] ])
    rider = tenant { SchoolRider.find_by!(dependant_id: ethan.id) }
    expect(tenant { FamilyRider.find_by!(rid: rider.rid) }).to have_attributes(family_id: fam.id, dependant_id: ethan.id)

    api(:get, api_v1_convoy_app_school_request_path(ids.first))
    d = json[:data]
    expect(d).to include(status: "Accepted", badge: { label: "Accepted", tone: "success" }, offer: { by: "2026-11-04T09:00:00.000+08:00", hours_left: 48 })
    expect(d[:first_invoice]).to include(total: "840.0", paid: false)
    expect(d[:can]).to include(pay_first_invoice: true)
    expect(d[:timeline].map { it[:state] }).to eq(%w[done done current todo])
    api(:get, api_v1_convoy_app_school_request_path(ids.first), token: david_token)
    expect(json[:data][:first_invoice]).to be_nil

    # Delete Family is refused while the offer waits for its first invoice
    api(:delete, api_v1_convoy_app_household_path)
    expect(json.dig(:error, :details, :reasons).pluck(:code)).to include("open_request", "unpaid_bill")
  end

  context "once a child rides" do
    let!(:rid) do
      apply(child(ethan))
      id = json[:data].first[:id]
      tenant do
        req = BusRequest.find(id)
        fee = req.registration_bill
        SchoolBills::RecordPayment.call(f[:school], [ [ fee, fee.total ] ], paid_on: Date.current, method: "PayNow", user: staff)
        BusRequests::Accept.call([ req.reload ], user: staff, quote: { amount: 840, start_on: "2027-01-04" })
        BusRequests::RecordPayment.call(req.reload, method: "PayNow", user: staff)
        rider = req.reload.school_rider
        plan = f[:school].plans.create!(name: "AM Plan", session: "am", effective_from: Date.new(2027, 1, 1))
        route = plan.routes.create!(number: 1, label: "AM 1", start_time: "06:40", end_time: "07:30", student_seats: 20)
        stop = route.stops.create!(position: 0, name: "Blk 412 Bedok North Ave 2", scheduled_time: "06:55", lat: 1.3236, lng: 103.93)
        SchoolRouteRider.create!(school_route: route, stop:, rid: rider.rid)
        bus = Vehicle.create!(plate: "PC7475L", seats: 40, make: "Yutong", model: "ZK6107", driver_name: "Ahmad Ali", driver_phone: "+65 9123 4567")
        route.vehicle_changes.create!(effective_from: "2027-01-01", vehicle: bus)
        rider.rid
      end
    end

    it "shows the rider card, Bus Information and the Active badge" do
      later(Time.zone.local(2027, 1, 4, 6, 0))
      api(:get, api_v1_convoy_app_school_path)
      card = json.dig(:data, :riders).sole
      expect(card).to include(name: "Ethan Tan", rid:, next_bus_date: "2027-01-04", today: true, can_track: true)
      expect(card[:legs].first).to include(session: "am", main: "Pick-up · 06:55", status: "Scheduled", route: "SSS AM 1", school_time: "07:30")
      expect(card[:legs].second).to include(session: "pm", main: "Not on a route yet")
      expect(json.dig(:data, :children).map { it[:name] }).to eq([ "Lucas Tan" ])
      expect(json.dig(:data, :actions)).to include(bus_not_required: true, change_service: true, stop: true)

      api(:get, rider_bus_api_v1_convoy_app_school_path(ethan.id), session: "am")
      b = json[:data]
      expect(b[:bus]).to include(plate: "PC7475L", seats: 40, model: "Yutong ZK6107")
      expect(b[:rows]).to eq([ { key: "Route", value: "SSS AM 1" }, { key: "Pick-up Point", value: "Blk 412 Bedok North Ave 2" },
                               { key: "Pick-up Time", value: "06:55" }, { key: "Arrive at School", value: "07:30" }, { key: "Days", value: "Mon to Fri" } ])
      expect(b[:crew]).to eq([ { role: "Driver", name: "Ahmad Ali", phone: "+65 9123 4567", relief: false } ])
      expect(b[:guardians]).to eq(count: 2, text: "2 people can receive Ethan")

      api(:get, api_v1_convoy_app_household_path)
      expect(json.dig(:data, :children).first[:status]).to include(label: "Active")
      api(:delete, api_v1_convoy_app_household_path)
      expect(json.dig(:error, :details, :reasons).pluck(:code)).to eq([ "active_service" ])
    end

    it "sends Change Service and Stop requests with the notice from the policy" do
      later(Time.zone.local(2027, 1, 4, 9, 0))
      api(:get, changes_api_v1_convoy_app_school_path, kind: "svc")
      expect(json.dig(:data, :children).sole).to include(service: "both", fares: { both: "840.0", am: "504.0", pm: "504.0", cca: nil })
      monday = json.dig(:data, :from_dates).third

      api(:post, service_changes_api_v1_convoy_app_school_path, service_change: { from: monday, children: [ { dependant_id: ethan.id, service: "both" } ] })
      expect(json.dig(:error, :message)).to eq("Pick a different service for at least one child")
      api(:post, service_changes_api_v1_convoy_app_school_path, service_change: { from: monday, children: [ { dependant_id: ethan.id, service: "am" } ] })
      s = json[:data].sole
      expect(s).to include(kind: "svc", status: "Requested", line: "Sent to SimpleDrive on 4 Jan 2027")
      expect(s[:change]).to include(from_service: "Two Ways", to_service: "Morning Only", effective_on: monday)
      expect(tenant { BusRequest.find(s[:id]) }).to have_attributes(current_fare: 840, estimate: 504, adds: false, old_am: true, old_pm: true)

      api(:post, stops_api_v1_convoy_app_school_path, stop: { last_on: "2027-01-20", why: "other", children: [ { dependant_id: ethan.id } ] })
      expect(json.dig(:error, :message)).to eq("Say why the bus is no longer needed")
      api(:post, stops_api_v1_convoy_app_school_path, stop: { last_on: "2027-01-20", why: "move", children: [ { dependant_id: ethan.id } ] })
      st = json[:data].sole
      expect(st[:change]).to include(last_on: "2027-01-20", earliest_on: "2027-02-04", early: true, notice: { n: 1, unit: "months" })
      expect(st[:change][:stop_reason]).to eq("Moving house")
    end

    it "moves the Family's home once the company confirms a change of address the parent agreed to" do
      later(Time.zone.local(2027, 1, 4, 9, 0))
      fake_one_map.add("460216", 1.335, 103.935, "216 BEDOK NORTH STREET 1")
      api(:get, address_change_api_v1_convoy_app_school_path)
      a = json[:data]
      expect(a[:rule]).to include(notice_days: 14, start: "any", from: "2027-01-18", to: "2027-04-04")
      expect(a[:default_on]).to eq("2027-01-18")
      expect(a[:children].pluck(:name)).to eq([ "Ethan Tan" ])

      body = { postal: "460216", block: "216", street: "Bedok North St 1", floor: "05", unit: "22", move_on: "2027-01-16", update_home: true,
               children: [ { dependant_id: ethan.id } ] }
      api(:post, address_change_api_v1_convoy_app_school_path, address_change: body)
      expect(json.dig(:error, :message)).to eq("Pick the date from the calendar")
      api(:post, address_change_review_api_v1_convoy_app_school_path, address_change: body.merge(move_on: "2027-01-18"))
      expect(json.dig(:data, :children).sole).to include(current_fare: "840.0", new_fare: "840.0", moves: [ "Morning pick-up moves", "Afternoon drop-off moves" ])
      api(:post, address_change_api_v1_convoy_app_school_path, address_change: body.merge(move_on: "2027-01-18"))
      req = json[:data].sole
      expect(req[:change]).to include(update_home: true, new_address: "Blk 216 Bedok North St 1, #05-22")

      tenant { BusRequests::ConfirmChange.call(BusRequest.find(req[:id]), amount: 900, note: "Longer route", user: staff, stop: "Blk 216 Bedok North St 1") }
      api(:get, api_v1_convoy_app_school_path)
      banner = json.dig(:data, :address_change)
      expect(banner).to include(from: "2027-01-18", ask: true, request_ids: [ req[:id] ])
      expect(banner[:line]).to eq("SimpleDrive confirmed the change. The fare goes from S$840.00 to S$900.00 a month (Longer route). Agree to apply it.")
      expect(home.reload.postal).to eq("460412")

      api(:post, agree_api_v1_convoy_app_school_request_path(req[:id]), token: david_token, yes: true)
      expect(json[:data]).to include(status: "Active", line: "New pick-up: Blk 216 Bedok North St 1")
      expect(home.reload).to have_attributes(postal: "460216", block: "216", floor: "05", unit: "22", address: "Blk 216 Bedok North St 1, #05-22")
    end

    it "renews for the next year while the school takes renewals" do
      tenant do
        year = AcademicYears::Create.call(school: f[:school], start_year: 2028, start_month: 1)
        year.create_registration!(school: f[:school], status: "scheduled", renew_from: "2027-08-01", renew_to: "2027-09-30", general_from: "2027-10-01",
                                  general_to: "2028-08-31", service_starts_on: "2028-01-03")
        SchoolRider.find_by!(rid:).update!(grade: "P5")
      end
      later(Time.zone.local(2027, 8, 2, 9, 0))
      api(:get, changes_api_v1_convoy_app_school_path, kind: "renew")
      row = json.dig(:data, :children).sole
      expect(row).to include(year: "2028", next_level: "P6", final_level: false, fare_note: "The 2028 fare comes with SimpleDrive's confirmation")

      api(:post, renewals_api_v1_convoy_app_school_path, renewal: { children: [ { dependant_id: ethan.id, level: "" } ] })
      expect(json.dig(:error, :message)).to eq("Choose the level for 2028")
      api(:post, renewals_api_v1_convoy_app_school_path, renewal: { children: [ { dependant_id: ethan.id, level: "P6" } ] })
      r = json[:data].sole
      expect(r).to include(kind: "new", renew: true, year: "2028", level: "P6", start: hash_including(on: "2028-01-03"))
      expect(tenant { BusRequest.find(r[:id]) }).to have_attributes(tags: [ "Renewing" ], same: true, school_rider_id: be_present, source: "app")
    end
  end
end
