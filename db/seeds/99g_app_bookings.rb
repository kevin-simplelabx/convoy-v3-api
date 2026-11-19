# Convoy App Bookings (Phase 7). SimpleDrive takes Personal bookings; Personal bookings are paid by Card (+3.7%) or PayNow
# (Finance Settings defaults). St. Stephen's School gets Bill To funds (Admin Fund, CCA Fund, Parents Support Group), an
# Admin (Ms Lim Hui Ling) and an organisation approval flow (Otherwise → Admins), so a teacher's booking waits for her.
# Priya Nair (+65 9166 7720, priya_nair@moe.edu.sg, 99a / 99c) accepts her St. Stephen's booking link and has:
#   "P4 Learning Journey to Science Centre" — waiting for Ms Lim (Pending, approval preview);
#   "P5 Zoo Excursion" — approved by Ms Lim and confirmed by SimpleDrive (Current; cancel quote by late_cancel_hours);
#   "CCA Sports Day Transport" — confirmed, then SimpleDrive moved the pick-up time (Changed: Accept Changes / Can't Accept).
# Rachel Tan (+65 9188 2045, 99a) has Personal bookings with SimpleDrive (her Individual client is made by the first one):
#   "Family day at Sentosa" — paid by PayNow, waiting for SimpleDrive (Pending), receipt in her company's name;
#   "Airport run" — paid by Card, confirmed (Current).
# Idempotent: each booking is made once (by title); approvals / confirmations only when still waiting.
company = Company.find_by!(code: "SD")
company.update!(accepts_personal_bookings: true) unless company.accepts_personal_bookings?

with_company("SD") do
  owner = User.find_by!(email: "ops@simpledrive.sg")
  sss = Client.kept.find_by!(name: "St. Stephen's School")
  [ "Admin Fund", "CCA Fund", "Parents Support Group" ].each_with_index do |name, i|
    sss.bill_funds.find_or_create_by!(name:) { |f| f.assign_attributes(company_id: sss.company_id, position: i) }
  end
  sss.pickup_points.find_or_create_by!(name: "School Gate (Siglap View)") do |p|
    p.assign_attributes(company_id: sss.company_id, address: "20 Siglap View, Singapore 455789", lat: 1.3156, lng: 103.9262,
                        note: "Bus bay beside the guardhouse", created_by: owner)
  end

  email = "limhl@ststephens.edu.sg"
  account = PortalAccount.for_email!(email, name: "Lim Hui Ling")
  admin = sss.users.kept.find_or_initialize_by(email:)
  admin.update!(company_id: sss.company_id, name: "Lim Hui Ling", title: "Operations Manager", role: "adm", portal_account: account, created_by: owner)

  flow = ClientApprovalFlow.for!(sss, nil)
  unless flow.on?
    Portal::SaveApprovalRule.call(flow:, rule: flow.otherwise, params: { steps: [ { who: [ "admins" ] } ] })
    flow.update!(on: true)
  end
end

priya = AppIdentity.find_by!(kind: "email", value: "priya_nair@moe.edu.sg").app_account
ConvoyApp::Links::Match.call(account: priya)
link = ActsAsTenant.without_tenant { ClientUser.kept.find_by!(app_account_id: priya.id) }
ConvoyApp::Links::Answer.call(account: priya, kind: "bookings", id: link.id, accept: true) if link.app_link_invited?
rachel = AppIdentity.find_by!(kind: "mobile", value: "+6591882045").app_account

school = ConvoyApp::Bookings.account!(priya, "link-#{link.id}")
personal = ConvoyApp::Bookings.account!(rachel, "personal-#{company.id}")

ConvoyApp::Bookings.within(school) do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  types = SeedFiles.vehicle_types(company).order(:seats).to_a
  coach = types.find { |t| t.seats.to_i >= 40 } || types.last
  funds = school.client.bill_funds.index_by(&:name)
  gate = { name: "St. Stephen's School", address: "20 Siglap View, Singapore 455789", lat: 1.3156, lng: 103.9262, use: "pu", note: "Bus bay beside the guardhouse" }
  place = ->(name, lat, lng) { { name:, lat:, lng:, use: "do" } }
  book = lambda do |title, date, trip, fund|
    found = ConvoyApp::Bookings.visible(school).find_by(title:)
    next found if found

    ConvoyApp::Bookings::Submit.call(account: school, params: {
      payer: "client", agree: true, contact: { me: true },
      booking: { title:, client_bill_fund_id: funds.fetch(fund).id, po_number: "SSS-#{title.parameterize.upcase.first(8)}",
                 days: [ { date: date.iso8601, trips: [ trip.merge(vehicles: [ { vehicle_type_id: coach.id, count: (trip[:pax] / coach.seats.to_f).ceil } ]) ] } ] }
    })
  end
  approve = lambda do |booking|
    approval = Portal::Approval.for(booking) if booking.approval&.waiting?
    approval&.approve!(school.client.users.kept.find_by!(email: "limhl@ststephens.edu.sg"), note: "Approved")
    booking.trips.reload.select(&:pending?).each { Bookings::Approve.call(trip: it, user: ops, trip_value: 640, return_trip_value: (640 if it.two_way?)) }
    booking.reload
  end

  book.("P4 Learning Journey to Science Centre", Date.current + 12,
        { kind: "two_way", start_time: "08:30", return_time: "13:30", pax: 82, adults: 4, points: [ gate, place.("Science Centre Singapore", 1.3329, 103.7356) ] },
        "Admin Fund")

  zoo = book.("P5 Zoo Excursion", Date.current + 6,
              { kind: "two_way", start_time: "08:00", return_time: "12:30", pax: 40, adults: 3, points: [ gate, place.("Singapore Zoo", 1.4043, 103.7930) ] },
              "Parents Support Group")
  approve.(zoo)

  cca = book.("CCA Sports Day Transport", Date.current + 9,
              { kind: "one_way", start_time: "07:15", pax: 38, adults: 2, points: [ gate, place.("Kallang Stadium", 1.3024, 103.8743) ] },
              "CCA Fund")
  if cca.trips.first.pending? || cca.approval&.waiting?
    approve.(cca)
  end
  trip = cca.trips.first
  if trip.approved? && !trip.changes_made.exists?
    # SimpleDrive moves the pick-up: the edit of an approved trip is recorded as a change the school must accept (seed only:
    # Bookings::Save keeps approved trips locked, so the change is written as the form would for an open trip).
    trip.update_columns(status: "awaiting_ack", start_time: Clock.minutes("07:45")) # rubocop:disable Rails/SkipsModelValidations
    trip.changes_made.create!(company_id: trip.company_id, items: [ "Pick-up time: 07:15 to 07:45" ], changed_by: ops)
  end
end

ConvoyApp::Bookings.within(personal) do
  ops = User.find_by!(email: "ops@simpledrive.sg")
  types = SeedFiles.vehicle_types(company).order(:seats).to_a
  van = types.find { |t| t.seats.to_i >= 13 } || types.first
  car = types.first
  home = { name: "Home", address: "Blk 123 Tampines Street 11, Singapore 521123", lat: 1.3496, lng: 103.9568, use: "pu" }
  book = lambda do |title, date, trip, type, method, receipt = nil|
    account = ConvoyApp::Bookings.account!(rachel, personal.key)
    found = ConvoyApp::Bookings.visible(account).find_by(title:)
    next found if found

    ConvoyApp::Bookings::Submit.call(account:, params: {
      payer: "self", method:, agree: true, contact: { me: true }, receipt:,
      booking: { title:, days: [ { date: date.iso8601, trips: [ trip.merge(vehicles: [ { vehicle_type_id: type.id, count: 1 } ]) ] } ] }
    })
  end

  book.("Family day at Sentosa", Date.current + 10,
        { kind: "two_way", start_time: "09:00", return_time: "17:30", pax: 9, adults: 5, points: [ home, { name: "Resorts World Sentosa", lat: 1.2554, lng: 103.8205, use: "do" } ] },
        van, "paynow", { name: "Tan Family Office Pte. Ltd.", uen: "201912345K", address: "1 Raffles Place, Singapore 048616" })

  airport = book.("Airport run", Date.current + 4,
                  { kind: "airport", start_time: "05:30", pax: 3, adults: 3, airport_direction: "departure", terminal: "T3",
                    points: [ home, { name: "Changi Airport T3", lat: 1.3554, lng: 103.9867, use: "do" } ] },
                  car, "card")
  airport.trips.select(&:pending?).each { Bookings::Approve.call(trip: it, user: ops, trip_value: airport.estimate_amount.positive? ? airport.estimate_amount : 60) }
end

puts "Convoy App Bookings: #{priya.display_name} books for St. Stephen's School, #{rachel.display_name} books personally with SimpleDrive"
