require "rails_helper"

# Convoy App › Bookings: booking accounts (Personal + school links), New Booking (form, estimate with the approval preview,
# Send for Approval, Pay for Personal and Pay Myself), the list and detail, Accept Changes / Can't Accept, Cancel (scopes,
# the late-cancel charge shown first, unconfirmed parts at once, confirmed parts as a request OS accepts), Book Again,
# Pick a Point, Track Buses, and isolation between people. Today is Monday 16/11/2026 09:00 (company time).
RSpec.describe "Convoy App bookings" do
  before { travel_to Time.zone.local(2026, 11, 16, 9, 0) }

  let(:company) { create(:company, code: "SD", name: "SimpleDrive", accepts_personal_bookings: true, ops_phone: "+65 6123 4567") }
  let(:other) { create(:company, code: "EC", name: "Eastern Coaches") }
  let(:ops) { create(:user, :admin, company:) }
  let!(:f) do
    within_tenant(company) do
      small = create(:vehicle_type, name: "13-seater", seats: 13)
      big = create(:vehicle_type, name: "40-seater", seats: 40)
      RateCards::Save.call(card: RateCard.new, params: RateCards::Standard.params(name: "Standard Rates", types: [ small, big ]))
      school = create(:client, name: "St. Stephen's School", late_cancel_hours: 24)
      fund = school.bill_funds.create!(company_id: company.id, name: "CCA Fund")
      head = create(:client_user, client: school, email: "lim@ststephens.edu.sg", name: "Lim Hui Ling", role: "adm")
      teacher = create(:client_user, client: school, email: "priya@moe.edu.sg", name: "Priya Nair", role: "member")
      finance = create(:client_user, client: school, email: "kenneth@moe.edu.sg", name: "Kenneth Ong", role: "fin")
      flow = ClientApprovalFlow.for!(school, nil)
      Portal::SaveApprovalRule.call(flow:, rule: flow.otherwise, params: { steps: [ { who: [ "admins" ] } ] })
      flow.update!(on: true)
      { small:, big:, school:, fund:, head:, teacher:, finance: }
    end
  end

  # A teacher: mobile + verified work email matching the client user, link accepted.
  def teacher(mobile: "9166 7720", email: "priya@moe.edu.sg", name: %w[Priya Nair])
    account, token = app_user(mobile:, name:)
    app_add_identity(token, kind: "email", value: email, tag: "work")
    user = ActsAsTenant.without_tenant { ClientUser.find_by!(app_account_id: account.id) }
    post "/api/v1/app/organisations/bookings/#{user.id}/accept", headers: app_as(token), as: :json
    expect(response).to have_http_status(:ok), json.inspect
    { account:, token:, h: app_as(token), key: "link-#{user.id}", personal: "personal-#{company.id}" }
  end

  def person(mobile: "9188 2045", name: %w[Rachel Tan])
    account, token = app_user(mobile:, name:)
    { account:, token:, h: app_as(token), key: "personal-#{company.id}" }
  end

  def pt(name, use = "both", **extra) = { name:, use:, lat: 1.3, lng: 103.8 }.merge(extra)
  def trip(pax: 30, adults: 2, type: f[:big], start: "08:00", kind: "one_way", **extra)
    { kind:, start_time: start, pax:, adults:, points: [ pt("St. Stephen's School", "pu", note: "Bus bay"), pt("Science Centre", "do") ],
      vehicles: [ { vehicle_type_id: type.id, count: 1 } ] }.merge(extra)
  end
  def booking(days: [ [ "2026-11-20", [ trip ] ] ], **extra)
    { title: "P4 Learning Journey", days: days.map { |date, trips| { date:, trips: } } }.merge(extra)
  end

  def submit(who, account: who[:key], payer: "client", booking: self.booking(client_bill_fund_id: f[:fund].id), **extra)
    post "/api/v1/app/bookings", params: { account:, payer:, booking:, agree: true, contact: { me: true } }.merge(extra), headers: who[:h], as: :json
    json
  end

  def show(who, id) = get("/api/v1/app/bookings/#{id}", headers: who[:h]) && json
  def list(who, tab, account: who[:key]) = get("/api/v1/app/bookings", params: { account:, tab: }, headers: who[:h]) && json

  def approve_all(id)
    within_tenant(company) do
      b = Booking.find(id)
      Portal::Approval.for(b).approve!(f[:head]) if b.approval&.waiting?
      b.trips.reload.select(&:pending?).each { Bookings::Approve.call(trip: it, user: ops, trip_value: 300, return_trip_value: (300 if it.two_way?)) }
    end
  end

  it "lists Personal and the school links that may book, never a paused, unaccepted or non-booking link" do
    t = teacher
    within_tenant(company) do
      create(:client_user, client: create(:client, name: "Other School"), email: "priya@moe.edu.sg", name: "Priya", role: "fin")
    end
    get "/api/v1/app/bookings/accounts", headers: t[:h]
    expect(json.dig(:data, :accounts).pluck(:key)).to eq([ t[:personal], t[:key] ])
    expect(json.dig(:data, :accounts, 1)).to include(org: "St. Stephen's School", role: "Member", terms: "credit", company: hash_including(name: "SimpleDrive"))
    expect(json.dig(:data, :work_hint)).to be(false)

    other.update!(accepts_personal_bookings: false)
    rachel = person
    get "/api/v1/app/bookings/accounts", headers: rachel[:h]
    expect(json.dig(:data, :accounts)).to contain_exactly(hash_including(key: rachel[:key], org: "Personal", terms: "prepaid"))
    expect(json.dig(:data, :work_hint)).to be(true)

    travel 13.months
    t2 = { h: app_as(app_token(mobile: "9166 7720")) }
    get "/api/v1/app/bookings/accounts", headers: t2[:h]
    expect(json.dig(:data, :accounts).pluck(:kind)).to eq([ "personal" ]) # work email overdue: the link is paused
  end

  it "previews the approval and sends a school booking for approval, billed to a fund" do
    t = teacher
    get "/api/v1/app/bookings/form", params: { account: t[:key] }, headers: t[:h]
    payers = json.dig(:data, :payers)
    expect(payers.pluck(:key)).to eq(%w[client self])
    expect(payers[0]).to include(label: "St. Stephen's School", fund_required: true, funds: [ { id: f[:fund].id, name: "CCA Fund" } ])
    expect(payers[1][:methods].pluck(:key, :fee_text)).to eq([ [ "card", "+3.7% card fee" ], [ "paynow", "No fee" ] ])
    expect(json.dig(:data, :booker)).to include(name: "Priya Nair", phone: "+65 9166 7720")

    post "/api/v1/app/bookings/estimate", params: { account: t[:key], payer: "client", booking: booking }, headers: t[:h], as: :json
    expect(json.dig(:data, :approval)).to include(need: true, steps: [ hash_including(people: [ { id: f[:head].id, name: "Lim Hui Ling" } ]) ])
    expect(json.dig(:data, :total).to_d).to be_positive
    expect(json.dig(:data, :short_notice)).to be(false)

    data = submit(t, booking: booking)
    expect(data.dig(:error, :message)).to eq("Pick the fund to bill")
    post "/api/v1/app/bookings", params: { account: t[:key], booking: booking(client_bill_fund_id: f[:fund].id) }, headers: t[:h], as: :json
    expect(json.dig(:error, :code)).to eq("terms")

    data = submit(t)[:data]
    expect(response).to have_http_status(:created)
    expect(data).to include(status: "pending", status_label: "Pending", tab: "pending", payer: "client", note: "With Lim Hui Ling for approval")
    expect(data[:rows]).to include(hash_including(key: "bill_to", value: "St. Stephen's School · CCA Fund"), hash_including(key: "approver", value: "Lim Hui Ling"))
    expect(data[:trips][0]).to include(pax: 30, adults: 2, contact: { name: "Priya Nair", phone: "+65 9166 7720" }, no_bus_text: "Buses are assigned once approved and confirmed.")
    within_tenant(company) do
      b = Booking.find(data[:id])
      expect([ b.source, b.created_by_client_user, b.title, b.bill_fund, b.terms_accepted_at.present? ]).to eq([ "app", f[:teacher], "P4 Learning Journey", f[:fund], true ])
      expect(b.trips.first).to be_awaiting_client
    end

    approve_all(data[:id])
    expect(show(t, data[:id])[:data]).to include(status: "confirmed", tab: "current")
    expect(list(t, "current")[:data].pluck(:id)).to eq([ data[:id] ])
    expect(list(t, "pending")[:data]).to be_empty
  end

  it "takes a Personal booking paid at once (simulated), on an Individual client per person whose name may repeat" do
    rachel = person
    other_rachel = person(mobile: "9177 3301", name: %w[Rachel Tan])
    params = { method: "card", booking: booking(days: [ [ "2026-11-17", [ trip(pax: 4, type: f[:small]) ] ] ]),
               receipt: { name: "Tan Family Office", uen: "201912345k", address: "1 Raffles Place" } }
    data = submit(rachel, payer: "self", **params)[:data]
    expect(response).to have_http_status(:created), json.inspect
    expect(data).to include(status: "pending", payer: "self", short_notice: true, receipt: { name: "Tan Family Office", uen: "201912345K", address: "1 Raffles Place" })
    expect(data[:banner][:text]).to include("Short notice")
    submit(other_rachel, payer: "self", **params)
    expect(response).to have_http_status(:created), json.inspect

    within_tenant(company) do
      b = Booking.find(data[:id])
      pay = b.payments.sole
      expect(pay).to have_attributes(kind: "payment", method: "card", amount: b.estimate_amount, card_fee: (b.estimate_amount * 0.037).round(2))
      expect(data[:amount].to_d).to eq(pay.charged)
      expect(b.client).to have_attributes(kind: "individual", name: "Rachel Tan", app_account_id: rachel[:account].id)
      expect(Client.individual.where(name: "Rachel Tan").count).to eq(2)
      expect(b.trips.first).to be_pending # no approval: straight to the company
      expect(BookingEvent.where(booking: b).pluck(:kind)).to eq([ "new_booking" ])

      # Settled in the app: its runs are never billed on a Client Invoice
      Bookings::Approve.call(trip: b.trips.first, user: ops, trip_value: 100)
      expect(ClientInvoices::Billable.call(trip: Trip.find_by!(booking_trip_id: b.trips.first.id))).to be_empty
      # The person who booked hears it in the app's Alerts (the other Rachel does not)
      alert = AppNotification.find_by!(app_account_id: rachel[:account].id, kind: "booking_confirmed")
      expect(alert).to have_attributes(title: start_with("#{b.number} confirmed by"), target: "booking", target_id: b.id)
      expect(AppNotification.where(app_account_id: other_rachel[:account].id, kind: "booking_confirmed")).to be_empty
    end
    expect(submit(rachel, payer: "client").dig(:error, :message)).to eq("Personal bookings are paid by you")
  end

  # Booking alerts reach a teacher's link only while it can open the booking: not once the work email is past its 12 months.
  it "tells the linked teacher about the booking only while the link is live" do
    t = teacher
    id = submit(t)[:data][:id]
    approve_all(id)
    expect(AppNotification.where(app_account_id: t[:account].id, kind: "booking_confirmed").count).to eq(1)

    t[:account].identities.find_by!(value: "priya@moe.edu.sg").update!(verified_at: 13.months.ago) # paused
    within_tenant(company) do
      trip = Booking.find(id).trips.first
      Bookings::TripAction.call(trip:, action: "reject", actor: ops, reason: "No bus") if trip.may_reject?
      ConvoyApp::Alerts::Bookings.call(booking: Booking.find(id), kind: "declined", trip:)
    end
    expect(AppNotification.where(app_account_id: t[:account].id, kind: "booking_declined")).to be_empty
  end

  it "keeps a Pay Myself booking from a school account on the school account, not on Personal" do
    t = teacher
    data = submit(t, payer: "self", method: "paynow", booking: booking)[:data]
    expect(response).to have_http_status(:created), json.inspect
    expect(list(t, "all")[:data].pluck(:id)).to eq([ data[:id] ])
    expect(list(t, "all", account: t[:personal])[:data]).to be_empty
    within_tenant(company) do
      b = Booking.find(data[:id])
      expect([ b.client.kind, b.booked_via_client_user, b.created_by_app_account, b.approval ]).to eq([ "individual", f[:teacher], t[:account], nil ])
    end
  end

  it "never shows one person's bookings to another" do
    t = teacher
    id = submit(t)[:data][:id]
    rachel = person
    personal_id = submit(rachel, payer: "self", method: "paynow")[:data][:id]

    expect(show(rachel, id)).to include(error: hash_including(code: "not_found"))
    expect(show(t, personal_id)).to include(error: hash_including(code: "not_found"))
    get "/api/v1/app/bookings", params: { account: t[:key] }, headers: rachel[:h]
    expect(response).to have_http_status(:not_found)
    post "/api/v1/app/bookings/#{id}/cancel", params: { scope: "booking", reason: "Trip postponed" }, headers: rachel[:h], as: :json
    expect(response).to have_http_status(:not_found)
    # A Portal booking by another teacher of the same school is not in Priya's list
    within_tenant(company) do
      Portal::SubmitBooking.call(client_user: f[:head], params: booking.merge(coordinator_name: "Lim", client_bill_fund_id: f[:fund].id))
    end
    expect(list(t, "all")[:data].pluck(:id)).to eq([ id ])
  end

  it "cancels the unconfirmed part at once, free, and refunds a prepaid booking" do
    rachel = person
    data = submit(rachel, payer: "self", method: "card",
                          booking: booking(days: [ [ "2026-11-20", [ trip ] ], [ "2026-11-21", [ trip(start: "09:00") ] ] ]))[:data]
    get "/api/v1/app/bookings/#{data[:id]}/cancel", headers: rachel[:h]
    scopes = json.dig(:data, :scopes)
    expect(scopes.pluck(:label)).to eq([ "Whole Booking", "Day 1 · Fri 20 Nov", "Day 2 · Sat 21 Nov" ])
    expect(scopes[1]).to include(fee: "0.0", confirmed: false, fee_text: "No charge: SimpleDrive has not confirmed the buses yet")

    post "/api/v1/app/bookings/#{data[:id]}/cancel", params: { scope: scopes[1][:key], reason: "Nope" }, headers: rachel[:h], as: :json
    expect(json.dig(:error, :message)).to eq("Pick a reason")
    post "/api/v1/app/bookings/#{data[:id]}/cancel", params: { scope: scopes[1][:key], reason: "Trip postponed", note: "Rain" }, headers: rachel[:h], as: :json
    expect(response).to have_http_status(:ok), json.inspect
    expect(json.dig(:meta, :request_id)).to be_nil
    expect(json.dig(:data, :days).pluck(:cancelled)).to eq([ true, false ])
    within_tenant(company) do
      b = Booking.find(data[:id])
      refund = b.payments.select(&:refund?).sole
      cancelled = b.trips.find(&:cancelled?)
      expect(refund.amount).to eq(cancelled.estimate_amount)
      expect(BookingEvent.where(booking: b, kind: "client_cancelled").sole.message).to include("Trip postponed: Rain")
    end
  end

  it "quotes the late-cancel charge first, sends a request for confirmed trips, and OS accepting cancels the runs as asked" do
    t = teacher
    data = submit(t, booking: booking(days: [ [ "2026-11-17", [ trip(start: "08:00") ] ], [ "2026-11-25", [ trip ] ] ], client_bill_fund_id: f[:fund].id))[:data]
    approve_all(data[:id])
    day1, day2 = within_tenant(company) { Booking.find(data[:id]).days.to_a }
    runs = within_tenant(company) { TripOccurrence.visible.where(trip_id: Trip.where(booking_trip_id: day1.trips.ids).select(:id)).to_a }
    expect(runs.size).to eq(1)

    get "/api/v1/app/bookings/#{data[:id]}/cancel", headers: t[:h]
    by = json.dig(:data, :scopes).index_by { it[:key] }
    expect(by["day-#{day1.id}"]).to include(fee: runs.sum(&:price).to_s, confirmed: true, fee_text: "Full charge: less than 24 hours before the trip")
    expect(by["day-#{day2.id}"]).to include(fee: "0.0", fee_text: "No charge: more than 24 hours before the trip")
    expect(by["booking"][:fee_text]).to eq("Per trip: full charge within 24 hours of the start, free before that")
    expect(show(t, data[:id])[:data][:actions]).to include(cancel: true, cancel_label: "Request Cancellation")

    post "/api/v1/app/bookings/#{data[:id]}/cancel", params: { scope: "day-#{day1.id}", reason: "Trip called off" }, headers: t[:h], as: :json
    expect(response).to have_http_status(:ok), json.inspect
    expect(json.dig(:data, :trips, 0, :status)).to eq("cancel_requested")
    within_tenant(company) do
      request = BookingCancelRequest.find(json.dig(:meta, :request_id))
      expect(request).to have_attributes(scope: "day", booking_day: day1, fee_quoted: runs.sum(&:price), requested_by_client_user: f[:teacher], reason: "Trip called off")
      travel 30.minutes
      Bookings::CancelRequest.call(request:, decision: "accept", user: ops)
      run = runs.first.reload
      expect(run).to have_attributes(status: "cancelled", cancelled_by_client: true, cancelled_at: request.requested_at)
      expect(day1.trips.first.reload).to be_cancelled
      expect(day2.trips.first.reload).to be_approved
      entity = ClientInvoices::Billable.call(month: Date.new(2026, 11, 1), today: Date.new(2026, 11, 30), client_id: f[:school].id).sole
      expect(entity.late.map(&:id)).to eq([ run.id ]) # billed as the late cancellation quoted
    end
    expect(show(t, data[:id])[:data][:rows]).to include(hash_including(label: "Cancelled", value: a_string_including("charge")))
  end

  it "asks to cancel a whole confirmed booking (Cancel Requested) and refuses a trip under way" do
    rachel = person
    data = submit(rachel, payer: "self", method: "paynow", booking: booking(days: [ [ "2026-11-16", [ trip(start: "09:20") ] ] ]))[:data]
    approve_all(data[:id])
    travel 5.minutes # 09:05: on the way (30 min before the start), still before the pick-up time
    get "/api/v1/app/bookings/#{data[:id]}/cancel", headers: rachel[:h]
    expect(json.dig(:data, :scopes)).to be_empty
    post "/api/v1/app/bookings/#{data[:id]}/cancel", params: { scope: "booking", reason: "Trip called off" }, headers: rachel[:h], as: :json
    expect(json.dig(:error, :code)).to eq("not_cancellable")
    expect(show(rachel, data[:id])[:data]).to include(status: "ongoing", actions: hash_including(cancel: false, call_ops: true, track: true))

    other = submit(rachel, payer: "self", method: "paynow", booking: booking(days: [ [ "2026-11-18", [ trip ] ] ]))[:data]
    approve_all(other[:id])
    post "/api/v1/app/bookings/#{other[:id]}/cancel", params: { scope: "booking", reason: "Trip called off" }, headers: rachel[:h], as: :json
    expect(json[:data]).to include(status: "cxreq", status_label: "Cancel Requested", note: "Cancellation sent · SimpleDrive confirms it")
    within_tenant(company) do
      request = BookingCancelRequest.find(json.dig(:meta, :request_id))
      expect(request).to have_attributes(scope: "booking", fee_quoted: 0, requested_by_app_account: rachel[:account])
      Bookings::CancelRequest.call(request:, decision: "accept", user: ops)
      b = Booking.find(other[:id])
      expect(Bookings::Prepaid.left(b)).to eq(0) # refunded in full: more than 24 hours before
    end
    expect(show(rachel, other[:id])[:data]).to include(status: "cancelled", tab: "past")
  end

  # OS and the app act on the same booking one at a time (booking row lock): a copy loaded before the other side acted is
  # checked again as the row is now, so a request is resolved once and a trip the client cancelled is neither approved
  # nor declined (no second refund).
  it "resolves a cancel request once and never approves or declines a trip the client cancelled meanwhile" do
    rachel = person
    data = submit(rachel, payer: "self", method: "card", booking: booking(days: [ [ "2026-11-18", [ trip ] ] ]))[:data]
    approve_all(data[:id])
    post "/api/v1/app/bookings/#{data[:id]}/cancel", params: { scope: "booking", reason: "Trip called off" }, headers: rachel[:h], as: :json
    expect(response).to have_http_status(:ok), json.inspect
    within_tenant(company) do
      first = BookingCancelRequest.find(json.dig(:meta, :request_id))
      stale = BookingCancelRequest.find(first.id)
      Bookings::CancelRequest.call(request: first, decision: "accept", user: ops)
      expect { Bookings::CancelRequest.call(request: stale, decision: "accept", user: ops) }
        .to raise_error(ApplicationService::Error, "This request is accepted already")
      expect(Booking.find(data[:id]).payments.count(&:refund?)).to eq(1)
    end

    pending = submit(rachel, payer: "self", method: "card", booking: booking(days: [ [ "2026-11-19", [ trip ] ], [ "2026-11-20", [ trip ] ] ]))[:data]
    a, b = within_tenant(company) { Booking.find(pending[:id]).trips.sort_by(&:date).map { BookingTrip.find(it.id) } }
    post "/api/v1/app/bookings/#{pending[:id]}/cancel", params: { scope: "booking", reason: "Trip postponed" }, headers: rachel[:h], as: :json
    expect(response).to have_http_status(:ok), json.inspect
    within_tenant(company) do
      expect { Bookings::Approve.call(trip: a, user: ops, trip_value: 300) }.to raise_error(ApplicationService::Error, "This trip is cancelled already")
      expect(Trip.where(booking_trip_id: a.id)).to be_empty
      expect { Bookings::TripAction.call(trip: b, action: "reject", actor: ops, reason: "No bus") }
        .to raise_error(ApplicationService::Error, "This trip is cancelled, so it can't be changed here")
      expect(Booking.find(pending[:id]).payments.count(&:refund?)).to eq(1) # the cancel's refund only, none for the decline
    end
  end

  # A request keeps the trips it was sent for: accepting "Rest of the Booking" never touches a day that already ran, and a
  # prepaid booking gets back what those trips paid, not an estimate worked out again later.
  it "cancels only the trips a request was sent for and refunds what they paid" do
    rachel = person
    days = [ [ "2026-11-17", [ trip(start: "08:00") ] ], [ "2026-11-25", [ trip ] ], [ "2026-11-26", [ trip ] ] ]
    data = submit(rachel, payer: "self", method: "card", booking: booking(days:))[:data]
    approve_all(data[:id])
    ran, d2, d3 = within_tenant(company) { Booking.find(data[:id]).trips.sort_by(&:date) }
    expect([ ran, d2, d3 ].map(&:paid_amount)).to eq([ ran, d2, d3 ].map(&:estimate_amount))

    travel_to Time.zone.local(2026, 11, 17, 12, 0) # day 1 has run
    post "/api/v1/app/bookings/#{data[:id]}/cancel", params: { scope: "booking", reason: "Trip called off" }, headers: rachel[:h], as: :json
    expect(response).to have_http_status(:ok), json.inspect
    expect(json.dig(:data, :trips).to_h { [ it[:id], it[:status] ] }).to include(d2.id => "cancel_requested", d3.id => "cancel_requested")
    expect(json.dig(:data, :trips).find { it[:id] == ran.id }[:status]).not_to eq("cancel_requested")
    within_tenant(company) do
      request = BookingCancelRequest.find(json.dig(:meta, :request_id))
      expect(request.request_trips.map(&:booking_trip_id)).to contain_exactly(d2.id, d3.id)
      d2.update_column(:estimate_amount, 999) # rubocop:disable Rails/SkipsModelValidations -- an estimate worked out again later
      Bookings::CancelRequest.call(request:, decision: "accept", user: ops)
      expect([ ran, d2, d3 ].map { it.reload.status }).to eq(%w[approved cancelled cancelled])
      b = Booking.find(data[:id])
      expect(b.payments.select(&:refund?).sum(&:amount)).to eq(d2.paid_amount + d3.paid_amount)
      expect(Bookings::Prepaid.left(b)).to eq(ran.paid_amount)
    end
  end

  # What a prepaid booking paid is kept: the company may change times and stops, but not remove a trip (declining refunds
  # it) or add trips / vehicles.
  it "keeps what a prepaid booking paid when the company edits it" do
    rachel = person
    data = submit(rachel, payer: "self", method: "paynow", booking: booking(days: [ [ "2026-11-20", [ trip, trip(start: "14:00") ] ] ]))[:data]
    within_tenant(company) do
      b = Booking.find(data[:id])
      day = b.days.sole
      t1, t2 = day.trips.sort_by(&:start_time)
      edit = ->(trips) { Bookings::Save.call(booking: Booking.find(b.id), params: { days: [ { id: day.id, date: "2026-11-20", trips: } ] }, actor: ops) }
      expect { edit.([ trip.merge(id: t1.id) ]) }.to raise_error(ApplicationService::Error, /Decline the trip instead of removing it/)
      expect { edit.([ trip.merge(id: t1.id), trip(start: "14:00").merge(id: t2.id), trip(start: "18:00") ]) }
        .to raise_error(ApplicationService::Error, /Trips can't be added/)
      expect { edit.([ trip.merge(id: t1.id), trip(start: "14:00", type: f[:small]).merge(id: t2.id, pax: 10) ]) }
        .to raise_error(ApplicationService::Error, /Vehicles can't be added or changed/)

      paid = t1.paid_amount
      edit.([ trip(start: "09:00").merge(id: t1.id), trip(start: "14:00").merge(id: t2.id) ])
      expect(t1.reload).to have_attributes(start_time: 540, paid_amount: paid)
    end
  end

  # A double tap or a retry after a timeout sends the same submit_token: the booking made the first time comes back (200),
  # nothing new is made or charged. A prepaid booking can't hold a vehicle the rate card has no price for.
  it "makes one booking per form however often it is sent, and never charges a vehicle without a price" do
    rachel = person
    params = { method: "card", submit_token: "8c1f2b9e-4d2a-4e0b-9a51-3f1d0c7e6a10", booking: booking(days: [ [ "2026-11-20", [ trip ] ] ]) }
    first = submit(rachel, payer: "self", **params)[:data]
    expect(response).to have_http_status(:created), json.inspect
    again = submit(rachel, payer: "self", **params)[:data]
    expect(response).to have_http_status(:ok), json.inspect
    expect(again[:id]).to eq(first[:id])
    within_tenant(company) do
      expect(Booking.where(submit_token: params[:submit_token]).count).to eq(1)
      expect(Booking.find(first[:id]).payments.count(&:payment?)).to eq(1)
    end

    t = teacher
    sent = submit(t, submit_token: "school-form-1")[:data]
    expect(response).to have_http_status(:created), json.inspect
    expect(submit(t, submit_token: "school-form-1")[:data][:id]).to eq(sent[:id])
    expect(response).to have_http_status(:ok)

    van = within_tenant(company) { create(:vehicle_type, name: "Van", seats: 8) }
    get "/api/v1/app/bookings/form", params: { account: rachel[:key] }, headers: rachel[:h]
    names = json.dig(:data, :payers).find { it[:key] == "self" }[:vehicle_types].pluck(:name)
    expect(names).to include("13-seater", "40-seater")
    expect(names).not_to include("Van")
    bad = submit(rachel, payer: "self", method: "card", booking: booking(days: [ [ "2026-11-21", [ trip(pax: 4, type: van) ] ] ]))
    expect(bad[:error]).to include(code: "no_price", message: "We can't price a Van online. Call SimpleDrive or pick another vehicle")
  end

  it "accepts changes or replies to them, and OS sees the reply" do
    t = teacher
    data = submit(t)[:data]
    approve_all(data[:id])
    within_tenant(company) do
      trip = Booking.find(data[:id]).trips.first
      trip.update_columns(status: "awaiting_ack") # rubocop:disable Rails/SkipsModelValidations
      trip.changes_made.create!(company_id: company.id, items: [ "Pick-up time: 08:00 to 08:30" ], changed_by: ops)
    end
    d = show(t, data[:id])[:data]
    expect(d).to include(status: "changed", note: "Changes from SimpleDrive waiting for your acceptance")
    expect(d[:banner]).to include(accept_changes: true, reply_label: "Can't Accept", text: a_string_including("Pick-up time: 08:00 to 08:30"))

    post "/api/v1/app/bookings/#{data[:id]}/reply", params: { reason: "The new time does not work", message: "Gates open at 08:00" }, headers: t[:h], as: :json
    expect(json[:data]).to include(note: "You replied. SimpleDrive is sending another option")
    expect(json.dig(:data, :banner, :reply_label)).to eq("Reply Again")
    within_tenant(company) do
      expect(BookingEvent.where(kind: "change_reply").sole.message).to include("Gates open at 08:00")
      expect(BookingChangeReply.sole.replied_by_client_user).to eq(f[:teacher])
    end

    post "/api/v1/app/bookings/#{data[:id]}/accept_changes", headers: t[:h], as: :json
    expect(response).to have_http_status(:ok), json.inspect
    within_tenant(company) { expect(Booking.find(data[:id]).trips.first).to have_attributes(status: "pending", acknowledged_how: "Convoy App", acknowledged_by_client_user: f[:teacher]) }
    post "/api/v1/app/bookings/#{data[:id]}/accept_changes", headers: t[:h], as: :json
    expect(json.dig(:error, :code)).to eq("no_changes")
  end

  it "copies a booking to a new first day (Book Again) and keeps the source on the new booking" do
    t = teacher
    data = submit(t, booking: booking(days: [ [ "2026-11-20", [ trip ] ], [ "2026-11-21", [ trip ] ] ], client_bill_fund_id: f[:fund].id, po_number: "PO-1"))[:data]
    get "/api/v1/app/bookings/#{data[:id]}/copy", params: { first_day: "2026-12-24" }, headers: t[:h]
    copy = json[:data]
    expect(copy[:days].map { it.slice(:date, :flag) }).to eq([ { date: "2026-12-24", flag: nil }, { date: "2026-12-25", flag: nil } ])
    expect(copy[:booking]).not_to have_key(:po_number)
    expect(copy[:booking][:days][0][:trips][0]).to include(pax: 30, adults: 2, points: [ hash_including(note: "Bus bay"), hash_including(name: "Science Centre") ])
    get "/api/v1/app/bookings/#{data[:id]}/copy", params: { first_day: "2026-11-01" }, headers: t[:h]
    expect(json.dig(:error, :message)).to eq("Pick a date from today")

    again = submit(t, booking: copy[:booking], copied_from_id: data[:id])[:data]
    expect(response).to have_http_status(:created), json.inspect
    expect(again[:rows]).to include(hash_including(key: "copied_from", value: data[:number]))
  end

  it "lists organisation points, My Points and Recent, and saves points (organisation: booking admins only)" do
    t = teacher
    submit(t)
    get "/api/v1/app/bookings/points", params: { account: t[:key] }, headers: t[:h]
    expect(json[:data]).to include(org_name: "St. Stephen's School", can_save_org: false, org: [], mine: [])
    expect(json.dig(:data, :recent).pluck(:name)).to contain_exactly("St. Stephen's School", "Science Centre")

    post "/api/v1/app/bookings/points", params: { account: t[:key], to: "org", name: "Gate B" }, headers: t[:h], as: :json
    expect(response).to have_http_status(:forbidden)
    post "/api/v1/app/bookings/points", params: { account: t[:key], to: "me", name: "Science Centre", address: "15 Science Centre Rd", note: "Coach bay" }, headers: t[:h], as: :json
    expect(response).to have_http_status(:created)
    post "/api/v1/app/bookings/points", params: { account: t[:key], to: "me", name: "science centre" }, headers: t[:h], as: :json
    expect(response).to have_http_status(:unprocessable_content)
    get "/api/v1/app/bookings/points", params: { account: t[:key] }, headers: t[:h]
    expect(json.dig(:data, :mine).pluck(:name)).to eq([ "Science Centre" ])
    expect(json.dig(:data, :recent).pluck(:name)).to eq([ "St. Stephen's School" ])

    within_tenant(company) { f[:teacher].update!(role: "sa") }
    post "/api/v1/app/bookings/points", params: { account: t[:key], to: "org", name: "Gate B", lat: 1.31, lng: 103.92 }, headers: t[:h], as: :json
    expect(json[:data]).to include(kind: "org", name: "Gate B", by: "Priya Nair")
    within_tenant(company) { expect(f[:school].pickup_points.sole.created_by_client_user).to eq(f[:teacher]) }
  end

  it "tracks the buses of a trip on the road today, plates and drivers shown from the day before" do
    rachel = person
    data = submit(rachel, payer: "self", method: "paynow", booking: booking(days: [ [ "2026-11-17", [ trip(start: "10:00") ] ] ]))[:data]
    approve_all(data[:id])
    within_tenant(company) do
      bus = create(:vehicle, plate: "PC7475L", make: "Scania", seats: 40, driver_name: "Eric Pang", driver_phone: "+6592104100")
      occ = TripOccurrence.visible.find_by!(trip: Trip.find_by!(booking_trip_id: Booking.find(data[:id]).trips.first.id))
      Occurrences::Move.call(occurrence: occ, vehicle: bus, scope: "one", user: ops)
    end
    bus = show(rachel, data[:id])[:data][:trips][0][:buses].sole
    expect(bus).to include(plate: "PC7475L", driver: hash_including(name: "Eric Pang"))
    expect(bus[:driver]).not_to have_key(:phone)
    get "/api/v1/app/bookings/#{data[:id]}/track", headers: rachel[:h]
    expect(response).to have_http_status(:not_found) # not on the road yet

    travel_to Time.zone.local(2026, 11, 17, 9, 40)
    rachel[:h] = app_as(app_token(mobile: "9188 2045"))
    get "/api/v1/app/bookings/#{data[:id]}/track", headers: rachel[:h]
    expect(response).to have_http_status(:ok), json.inspect
    trip = json.dig(:data, :trips, 0)
    expect(trip).to include(badge: "0 of 1 here", depart: { time: "10:00", name: "St. Stephen's School" })
    expect(trip[:buses].sole).to include(n: 1, plate: "PC7475L", state: "on_the_way", driver: hash_including(name: "Eric Pang", phone: "+6592104100"))
    expect(json.dig(:data, :company, :ops_phone)).to eq("+65 6123 4567")
  end
end
