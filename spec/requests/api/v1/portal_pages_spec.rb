require "rails_helper"

# Client Portal pages that read: Home (tiles, upcoming trips, today's shuttles, notices), Shuttles, Notices, Invoices.
RSpec.describe "Client Portal pages" do
  let(:company) { create(:company, code: "SD", name: "SimpleDrive") }
  let!(:f) do
    within_tenant(company) do
      small = create(:vehicle_type, name: "13-seater", seats: 13)
      RateCards::Save.call(card: RateCard.new, params: RateCards::Standard.params(name: "Standard Rates", types: [ small ]))
      google = create(:client, name: "Google")
      tower_a = google.sites.create!(company_id: company.id, name: "Tower A")
      tower_b = google.sites.create!(company_id: company.id, name: "Tower B", own_billing: true, billing_name: "Google B Pte Ltd")
      shuttle = create(:trip, client: google, client_site: tower_a, title: "Tower A Shuttle", days: [ 1, 2, 3, 4, 5 ], end_mode: "never",
                              starts_on: Date.new(2026, 10, 1), route_tags: [ "Staff" ])
      shuttle.update_columns(kind: "corporate_shuttle") # rubocop:disable Rails/SkipsModelValidations
      other = create(:trip, client: google, title: "Unmarked Shuttle", days: [ 1 ], end_mode: "never", starts_on: Date.new(2026, 10, 1))
      other.update_columns(kind: "corporate_shuttle") # rubocop:disable Rails/SkipsModelValidations
      run = ->(hour) do
        TripOccurrence.create!(trip: shuttle, client: google, date: Date.new(2026, 11, 2), start_time: hour * 60, end_time: hour * 60 + 30,
                               starts_at: Time.zone.local(2026, 11, 2, hour), ends_at: Time.zone.local(2026, 11, 2, hour, 30), kind: "corporate_shuttle",
                               trip_label: "S#{hour}", run_key: "r#{hour}", slot_no: hour)
      end
      run.(8)
      run.(9)
      run.(18)
      Notice.create!(company_id: company.id, audience: "trip", trip: shuttle, message: "No shuttle on Friday", starts_at: Time.zone.local(2026, 11, 1),
                     ends_at: Time.zone.local(2026, 11, 8))
      inv = ->(number, site, total, due, paid = 0) do
        i = ClientInvoice.create!(company_id: company.id, client: google, client_site: site, kind: "invoice", status: "issued", number:,
                                  bill_to_name: site&.billing_name || "Google", issued_on: due - 30, due_on: due, total:, subtotal: total)
        i.payments.create!(paid_on: due - 5, amount: paid, method: "PayNow") if paid.positive?
        i
      end
      inv.("INV-1", nil, 300, Date.new(2026, 10, 20), 100)
      inv.("INV-2", tower_b, 200, Date.new(2026, 11, 20))
      inv.("INV-3", nil, 50, Date.new(2026, 10, 1), 50)
      { small:, google:, tower_a:, tower_b:, shuttle:,
        admin: portal_user(google, email: "linh@google.com", role: "adm"),
        sa_a: portal_user(google, email: "tan@google.com", role: "sa", sites: [ tower_a ]),
        sfin_b: portal_user(google, email: "bee@google.com", role: "sfin", sites: [ tower_b ]),
        mo: portal_user(google, email: "mo@google.com", role: "member", sites: [ tower_a ]) }
    end
  end

  before { travel_to Time.zone.local(2026, 11, 2, 9, 10) }

  it "shows Home: tiles, the next trips, today's shuttles with where they are, notices in force" do
    trip = { kind: "one_way", start_time: "07:30", pax: 5, points: [ { name: "Changi", use: "pu" }, { name: "Tower A", use: "do" } ],
             vehicles: [ { vehicle_type_id: f[:small].id, count: 1 } ] }
    post api_v1_portal_bookings_path, params: { booking: { client_site_id: f[:tower_a].id, coordinator_name: "Mo", days: [ { date: "2026-11-04", trips: [ trip ] } ] } },
                                      headers: as(portal_token(f[:mo])), as: :json

    get api_v1_portal_home_path, headers: as(portal_token(f[:sa_a])), as: :json
    d = json[:data]
    expect(d[:tiles]).to include(upcoming_trips: { count: 1, next: { date: "2026-11-04", time: "07:30" } }, changes_to_review: 0, waiting_for_you: 0,
                                 shuttle_runs_today: { count: 3, on_road: 1 }, school_buses_today: nil, sites: { count: 1, own_entity: 0 })
    expect(d[:upcoming].first).to include(from: "Changi", to: "Tower A", status: "sent", site: "Tower A")
    expect(d[:shuttles_today].pluck(:label, :state)).to eq([ %w[S8 ended], %w[S9 started], %w[S18 scheduled] ])
    expect(d[:notices].pluck(:message)).to eq([ "No shuttle on Friday" ])

    get api_v1_portal_home_path, headers: as(portal_token(f[:sfin_b])), as: :json
    expect(json.dig(:data, :tiles)).to include(upcoming_trips: { count: 0, next: nil }, sites: { count: 1, own_entity: 1 })
    expect(json.dig(:data, :shuttles_today)).to eq([]) # Tower A's shuttle is not on their site
  end

  it "shows the shuttle routes by site, with Other Routes for people covering every site" do
    get api_v1_portal_shuttles_path, headers: as(portal_token(f[:admin])), as: :json
    expect(json[:data].map { [ it.dig(:site, :name), it[:routes].pluck(:title) ] }).to eq([ [ "Tower A", [ "Tower A Shuttle" ] ], [ nil, [ "Unmarked Shuttle" ] ] ])
    expect(json.dig(:data, 0, :routes, 0)).to include(days_text: "Mon to Fri", status: "active", tags: [ "Staff" ], cross_site: false)

    get api_v1_portal_shuttles_path, headers: as(portal_token(f[:sa_a])), as: :json
    expect(json[:data].map { it.dig(:site, :name) }).to eq([ "Tower A" ])
    expect(Portal::Shuttles.days_text([ 1, 3, 5 ])).to eq("Mon, Wed, Fri")
    expect(Portal::Shuttles.days_text([ 0, 1, 2, 3, 6 ])).to eq("Sun to Wed, Sat")
  end

  it "lists notices in force and scheduled for the trips the person covers" do
    get api_v1_portal_notices_path, headers: as(portal_token(f[:mo])), as: :json
    expect(json[:data]).to contain_exactly(hash_including(message: "No shuttle on Friday", state: "in_force", trip: { id: f[:shuttle].id, title: "Tower A Shuttle" }))
    get api_v1_portal_notices_path, headers: as(portal_token(f[:sfin_b])), as: :json
    expect(json[:data]).to eq([])
  end

  it "lists invoices for billing roles: what is still to pay, overdue, and only their sites for Site Finance" do
    get api_v1_portal_invoices_path, headers: as(portal_token(f[:mo])), as: :json
    expect(response).to have_http_status(:forbidden)

    get api_v1_portal_invoices_path, headers: as(portal_token(f[:admin])), as: :json
    d = json[:data]
    expect(d[:kpis]).to eq(outstanding: { amount: "400.0", count: 2 }, overdue: { amount: "200.0", count: 1 }, invoices: 3)
    expect(d[:rows].pluck(:number, :status, :balance)).to eq([ [ "INV-2", "Due", "200.0" ], [ "INV-1", "Overdue", "200.0" ], [ "INV-3", "Paid", "0.0" ] ])

    get api_v1_portal_invoices_path, params: { filter: "not_paid", q: "inv-1" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :rows).pluck(:number)).to eq([ "INV-1" ])
    get api_v1_portal_invoices_path, headers: as(portal_token(f[:sfin_b])), as: :json
    expect(json.dig(:data, :rows).pluck(:number, :for)).to eq([ [ "INV-2", "Google B Pte Ltd" ] ])
  end

  it "lists School Bus bills the client pays as a school (with the late fee), for people covering the school's site" do
    within_tenant(company) do
      school = School.create!(name: "Tower B Preschool")
      f[:tower_b].update!(school:)
      SchoolBill.create!(company_id: company.id, school:, client: f[:google], payer: "school", kind: "period", status: "issued", number: "SB-1",
                         bill_to: "Google B Pte Ltd", period_label: "Term 4 2026", issued_on: Date.new(2026, 9, 1), due_on: Date.new(2026, 10, 1),
                         subtotal: 1000, total: 1000)
    end
    get api_v1_portal_invoices_path, params: { filter: "school_bus" }, headers: as(portal_token(f[:sfin_b]))
    expect(json.dig(:data, :rows)).to contain_exactly(hash_including(kind: "school_bus", number: "SB-1", site: "Tower B", period: "Term 4 2026",
                                                                     status: "Overdue", balance: "1000.0"))
    get api_v1_portal_invoices_path, params: { filter: "school_bus" }, headers: as(portal_token(f[:admin]))
    expect(json.dig(:data, :rows).size).to eq(1)
    expect(json.dig(:data, :has_school_bus)).to be(true)
  end
end
