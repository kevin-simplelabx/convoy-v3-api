require "rails_helper"

# Client Portal › Bookings: who sees which bookings, New Booking (form, estimate with the approval it will get, the
# portal's own rules, Submit), the trip statuses in the portal's words, the bus, Accept Changes.
RSpec.describe "Client Portal bookings" do
  let(:company) { create(:company, code: "SD", name: "SimpleDrive") }
  let(:staff) { create(:user, :admin, company:) }
  let!(:f) do
    within_tenant(company) do
      small = create(:vehicle_type, name: "13-seater", seats: 13)
      big = create(:vehicle_type, name: "40-seater", seats: 40)
      RateCards::Save.call(card: RateCard.new, params: RateCards::Standard.params(name: "Standard Rates", types: [ small, big ]))
      google = create(:client, name: "Google", uen: "200817984R")
      google.bookable_vehicle_types.create!(company_id: company.id, vehicle_type: small)
      tower_a = google.sites.create!(company_id: company.id, name: "Tower A")
      tower_b = google.sites.create!(company_id: company.id, name: "Tower B", own_billing: true, billing_name: "Google B Pte Ltd")
      { small:, big:, google:, tower_a:, tower_b:,
        admin: portal_user(google, email: "linh@google.com", role: "adm"),
        sa_a: portal_user(google, email: "tan@google.com", role: "sa", sites: [ tower_a ]),
        mo: portal_user(google, email: "mo@google.com", role: "member", sites: [ tower_a ]),
        bee: portal_user(google, email: "bee@google.com", role: "member", sites: [ tower_b ]) }
    end
  end

  before { travel_to Time.zone.local(2026, 11, 2, 9, 0) }

  def pt(name, use = "both") = { name:, use: }
  def trip(pax: 10, type: f[:small], **extra)
    { kind: "one_way", start_time: "09:00", pax:, points: [ pt("Changi", "pu"), pt("Marina", "do") ],
      vehicles: [ { vehicle_type_id: type.id, count: 1 } ] }.merge(extra)
  end
  def booking(site: f[:tower_a], date: "2026-11-05", trips: [ trip ])
    { client_site_id: site&.id, coordinator_name: "Mo", days: [ { date:, trips: } ] }
  end

  it "keeps the portal's rules on New Booking" do
    token = portal_token(f[:mo])
    post api_v1_portal_bookings_path, params: { booking: booking(site: nil) }, headers: as(token), as: :json
    expect(json.dig(:error, :message)).to eq("Pick the site this booking is for")
    post api_v1_portal_bookings_path, params: { booking: booking(site: f[:tower_b]) }, headers: as(token), as: :json
    expect(json.dig(:error, :message)).to eq("Pick one of your sites")
    post api_v1_portal_bookings_path, params: { booking: booking(date: "2026-11-01") }, headers: as(token), as: :json
    expect(json.dig(:error, :message)).to eq("The first day can't be in the past")
    post api_v1_portal_bookings_path, params: { booking: booking(trips: [ trip(pax: 20) ]) }, headers: as(token), as: :json
    expect(json.dig(:error, :message)).to eq("05/11/2026: 20 passengers but 13 seats. Add a vehicle or pick a bigger one")
    post api_v1_portal_bookings_path, params: { booking: booking(trips: [ trip(type: f[:big]) ]) }, headers: as(token), as: :json
    expect(json.dig(:error, :message)).to eq("05/11/2026: pick vehicle types the company offers") # not a Bookable Vehicle

    get form_api_v1_portal_bookings_path, headers: as(token), as: :json
    expect(json[:data]).to include(site_required: true, coordinator: { name: "Mo", email: "mo@google.com" }, rate_card: hash_including(name: "Standard Rates"))
    expect(json.dig(:data, :vehicle_types).pluck(:name)).to eq([ "13-seater" ])
    expect(json.dig(:data, :sites).pluck(:name)).to eq([ "Tower A" ])
  end

  it "estimates while filling in, submits straight to the transport company, and tells its coordinators" do
    token = portal_token(f[:mo])
    post estimate_api_v1_portal_bookings_path, params: { booking: booking }, headers: as(token), as: :json
    expect(json[:data]).to include(billed_to: { name: "Google", uen: "200817984R", own: false }, approval: hash_including(need: false))
    expect(json.dig(:data, :total).to_d).to be_positive
    within_tenant(company) { expect(Booking.count).to eq(0) }

    post api_v1_portal_bookings_path, params: { booking: booking }, headers: as(token), as: :json
    expect(response).to have_http_status(:created), json.inspect
    data = json[:data]
    expect(data).to include(status: "sent", status_label: "Sent to Transport", site: { id: f[:tower_a].id, name: "Tower A" },
                            booked_by: { name: "Mo", in_portal: true, me: true }, approval: nil)
    expect(data[:number]).to match(/\ASD26\d{6}\z/)
    within_tenant(company) do
      b = Booking.find(data[:id])
      expect([ b.source, b.created_by_client_user, b.created_by_name ]).to eq([ "portal", f[:mo], "Mo" ])
      expect(BookingEvent.where(booking: b).pluck(:kind, :message)).to eq([ [ "new_booking", "New booking from Mo (Google) in the Client Portal" ] ])
    end
  end

  it "waits for the client's approval when a rule asks for it" do
    within_tenant(company) do
      flow = ClientApprovalFlow.for!(f[:google], nil)
      Portal::SaveApprovalRule.call(flow:, params: { name: "All", steps: [ { who: [ "site" ] } ] })
    end
    token = portal_token(f[:mo])
    post estimate_api_v1_portal_bookings_path, params: { booking: booking }, headers: as(token), as: :json
    expect(json.dig(:data, :approval)).to include(need: true, name: "All", steps: [ hash_including(people: [ { id: f[:sa_a].id, name: "Tan" } ]) ])

    post api_v1_portal_bookings_path, params: { booking: booking }, headers: as(token), as: :json
    expect(json[:data]).to include(status: "awaiting_approval", status_label: "Awaiting Approval")
    within_tenant(company) { expect(BookingEvent.count).to eq(0) } # the transport company sees it once approved
    get api_v1_portal_bookings_path, params: { tab: "awaiting" }, headers: as(token)
    expect(json[:data].size).to eq(1)
    expect(json.dig(:meta, :counts)).to eq(upcoming: 1, awaiting: 1, past: 0)
  end

  it "shows each person the bookings they may see" do
    mine = ->(user, site) { post(api_v1_portal_bookings_path, params: { booking: booking(site:) }, headers: as(portal_token(user)), as: :json) && json.dig(:data, :id) }
    a = mine.(f[:mo], f[:tower_a])
    b = mine.(f[:bee], f[:tower_b])
    no_site = within_tenant(company) do
      Bookings::Save.call(booking: Booking.new, actor: staff, params: { client_id: f[:google].id, coordinator_name: "VIP",
                                                                         days: [ { date: "2026-11-06", trips: [ trip ] } ] }).id
    end

    ids = ->(user) { get(api_v1_portal_bookings_path, headers: as(portal_token(user))) && json[:data].pluck(:id) }
    expect(ids.(f[:admin])).to contain_exactly(a, b, no_site)
    expect(ids.(f[:sa_a])).to eq([ a ]) # Tower A only; the booking with no site is for organisation-wide roles
    expect(ids.(f[:bee])).to eq([ b ]) # a Member: their own
    get api_v1_portal_booking_path(b), headers: as(portal_token(f[:mo])), as: :json
    expect(response).to have_http_status(:not_found)
    get api_v1_portal_booking_path(b), headers: as(portal_token(f[:admin])), as: :json
    expect(json[:data]).to include(billed_to: { name: "Google B Pte Ltd", uen: nil, own: true })
  end

  it "shows the bus once confirmed, and lets the client accept the transport company's changes" do
    token = portal_token(f[:mo])
    post api_v1_portal_bookings_path, params: { booking: booking(trips: [ trip, trip(start_time: "15:00") ]) }, headers: as(token), as: :json
    id = json.dig(:data, :id)
    one, two = json.dig(:data, :trips).pluck(:id)

    within_tenant(company) do
      Bookings::Approve.call(trip: BookingTrip.find(one), user: staff, trip_value: 1)
      bus = create(:vehicle, plate: "PD1A", seats: 13)
      Trip.find_by!(booking_trip_id: one).occurrences.find_by!(date: "2026-11-05").update!(vehicle: bus)
      b = Booking.find(id)
      Bookings::Save.call(booking: b, actor: staff, lock_version: b.lock_version, params: {
        client_id: f[:google].id, client_site_id: f[:tower_a].id, coordinator_name: "Mo",
        days: [ { id: b.days.first.id, date: "2026-11-05", trips: [ { id: one }, trip(start_time: "16:00").merge(id: two) ] } ]
      })
    end

    get api_v1_portal_booking_path(id), headers: as(token), as: :json
    first, second = json.dig(:data, :trips)
    expect(first).to include(status: "confirmed", buses: [ "PD1A" ])
    expect(second).to include(status: "changed", status_label: "Changes to Review", changes: [ "Pick-up time: 15:00 to 16:00" ], can_accept_changes: true)
    expect(json.dig(:data, :status)).to eq("changed")

    patch api_v1_portal_accept_changes_booking_trip_path(two), headers: as(token), as: :json
    second = json.dig(:data, :trips, 1)
    expect(second).to include(status: "sent", acknowledgement: hash_including(by: "Mo", how: "Client Portal"))
    within_tenant(company) do
      t = BookingTrip.find(two)
      expect([ t.acknowledged_by_client_user, t.acknowledged_by_kind ]).to eq([ f[:mo], "client_user" ])
      expect(BookingEvent.where(kind: "acknowledged").pluck(:message)).to eq([ "Mo accepted the changes to the trip on Thu 5/11" ])
    end
  end

  it "takes files with the booking (multipart: the booking as JSON)" do
    post api_v1_portal_bookings_path, headers: as(portal_token(f[:mo])),
         params: { booking: booking.to_json, files: [ fixture_file_upload("sample.pdf", "application/pdf") ] }
    expect(response).to have_http_status(:created), json.inspect
    expect(json.dig(:data, :attachments)).to contain_exactly(hash_including(name: "sample.pdf", content_type: "application/pdf"))
    within_tenant(company) { expect(BookingAttachment.last.uploaded_by_client_user).to eq(f[:mo]) }
  end

  it "adds a customer for Service For (main contractors only)" do
    post api_v1_portal_end_customers_path, params: { name: "DBS" }, headers: as(portal_token(f[:admin])), as: :json
    expect(json.dig(:error, :message)).to eq("Service For is for main contractors")
    within_tenant(company) { f[:google].update!(kind: "transport_company") }
    post api_v1_portal_end_customers_path, params: { name: "DBS" }, headers: as(portal_token(f[:admin])), as: :json
    id = json.dig(:data, :id)
    post api_v1_portal_end_customers_path, params: { name: " dbs " }, headers: as(portal_token(f[:admin])), as: :json
    expect(json.dig(:data, :id)).to eq(id)
  end
end
