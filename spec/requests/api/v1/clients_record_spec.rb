require "rails_helper"

# Client record page: sites (school, own billing, Send Invoices To, remove rule), their customers, bookable vehicles
# and saved pick-up points.
RSpec.describe "Client record" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, name: "Rachel Tan") }
  let!(:data) do
    within_tenant(company) do
      { client: create(:client, name: "Bright Steps"), school: School.create!(name: "Bright Steps (Punggol)"),
        van: create(:vehicle_type, name: "Van", seats: 13), coach: create(:vehicle_type, name: "Coach", seats: 45) }
    end
  end
  let(:client) { data[:client] }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(user)
  end

  def site(id: nil, **attrs)
    body = { client_site: attrs }
    id ? patch(api_v1_client_site_path(client, id), params: body, as: :json) : post(api_v1_client_sites_path(client), params: body, as: :json)
  end

  it "adds a site, links its school and bills it as its own entity" do
    site(name: "Punggol Centre", address: "1 Punggol Field", lat: 1.39, lng: 103.9)
    expect(response).to have_http_status(:created)
    id = json.dig(:data, :id)
    site(name: "punggol centre")
    expect(json.dig(:error, :details, :name)).to eq([ "Name is already a site of this client" ])

    site(id:, own_billing: true, billing_contacts: [ { name: "Ann", email: "ann@bs.sg", send_as: "cc" } ])
    expect(json.dig(:error, :details, :billing_name)).to eq([ "Billing name is needed: the legal name the site is billed as" ])

    site(id:, own_billing: true, billing_name: "Bright Steps (Punggol) Pte Ltd", billing_uen: "201912345k",
         billing_contacts: [ { name: "Ann", email: "ann@bs.sg", send_as: "cc" } ])
    expect(json.dig(:error, :message)).to eq("Send the invoice To at least one person, not only CC")

    site(id:, school_id: data[:school].id, own_billing: true, billing_name: "Bright Steps (Punggol) Pte Ltd", billing_uen: "201912345k",
         billing_contacts: [ { name: "Accounts", email: "AP@bs.sg", send_as: "to" }, { name: "Mr Lim", attention: true, email: "" },
                             { name: "", email: "" } ])
    expect(json[:data]).to include(own_billing: true, billing_uen: "201912345K", school: { id: data[:school].id, name: "Bright Steps (Punggol)" },
                                   billing_contacts: [ hash_including(name: "Accounts", email: "ap@bs.sg", send_as: "to", attention: false),
                                                       hash_including(name: "Mr Lim", email: nil, attention: true) ])

    site(id:, own_billing: false)
    expect(json[:data]).to include(billing_name: nil, billing_contacts: [])
  end

  it "keeps a site while trips use it" do
    site_rec = within_tenant(company) { client.sites.create!(name: "HQ") }
    trip = within_tenant(company) { create(:trip, client:, client_site: site_rec) }
    delete api_v1_client_site_path(client, site_rec)
    expect(json.dig(:error, :message)).to eq("HQ is on 1 shuttle trip. Unmark it in Stop Details first")

    within_tenant(company) { trip.discard! }
    delete api_v1_client_site_path(client, site_rec)
    expect(response).to have_http_status(:no_content)
    expect(trip.reload.client_site_id).to be_nil
  end

  it "sets the bookable vehicles, customers and pick-up points" do
    put bookable_vehicle_types_api_v1_client_path(client), params: { vehicle_type_ids: [ data[:coach].id ] }, as: :json
    expect(json.dig(:data, :bookable_vehicle_type_ids)).to eq([ data[:coach].id ])
    put bookable_vehicle_types_api_v1_client_path(client), params: { vehicle_type_ids: [] }, as: :json
    expect(json.dig(:data, :bookable_vehicle_type_ids)).to eq([])

    post api_v1_client_end_customers_path(client), params: { client_end_customer: { name: "NUS" } }, as: :json
    post api_v1_client_end_customers_path(client), params: { client_end_customer: { name: " nus " } }, as: :json
    expect(json.dig(:error, :details, :name)).to eq([ "Name is already on the list" ])

    post api_v1_client_pickup_points_path(client), params: { client_pickup_point: { name: "Main Gate", address: "1 Punggol Field", note: "Coach bay" } }, as: :json
    expect(json[:data]).to include(name: "Main Gate", note: "Coach bay", created_by: { id: user.id, name: "Rachel Tan" })
  end
end
