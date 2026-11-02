require "rails_helper"

# Managed Clients: the form (UEN, School link and calendar), the record and Delete Client rules.
RSpec.describe "Managed clients" do
  let(:company) { create(:company) }
  let!(:setup) do
    within_tenant(company) do
      school_cal = create(:calendar, name: "MOE 2026", kind: :school)
      { school: School.create!(name: "St. Stephen's School", short_name: "SSS"), school_cal:, office_cal: create(:calendar, name: "Office") }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:))
  end

  def save(id: nil, **attrs)
    body = { client: { name: "Bright Steps", kind: "company" }.merge(attrs) }
    id ? patch(api_v1_client_path(id), params: body, as: :json) : post(api_v1_clients_path, params: body, as: :json)
  end

  it "checks the UEN and links a school with its calendar" do
    save(uen: "12345")
    expect(json.dig(:error, :details, :uen)).to eq([ "Uen looks wrong. Examples: 53012345A, 201912345K, T09LL1234A" ])

    save(uen: "201912345k", school_id: setup[:school].id, school_calendar_id: setup[:school_cal].id)
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(uen: "201912345K", school: { id: setup[:school].id, name: "St. Stephen's School" },
                                   school_calendar: { id: setup[:school_cal].id, name: "MOE 2026" })
    id = json.dig(:data, :id)

    save(id:, school_id: setup[:school].id, school_calendar_id: setup[:office_cal].id)
    expect(json.dig(:error, :message)).to eq("Pick a school calendar")

    save(name: "Other School Co", school_id: setup[:school].id)
    expect(json.dig(:error, :message)).to eq("St. Stephen's School is already linked to Bright Steps")

    save(id:, kind: "individual", phone: "+65 9123 4567")
    expect(json[:data]).to include(kind: "individual", school: nil)
    expect(setup[:school].reload.client_id).to be_nil
  end

  it "refuses Delete Client while trips run or bookings are open, then deletes softly" do
    client = within_tenant(company) { create(:client, name: "Google") }
    trip = within_tenant(company) { create(:trip, client:, days: [ 1 ], end_mode: "never") }

    delete api_v1_client_path(client)
    expect(json.dig(:error, :message)).to eq("Google has 1 trip still running. End or delete them first")

    within_tenant(company) { trip.update!(end_mode: "date", ends_on: Date.new(2026, 10, 31), starts_on: Date.new(2026, 10, 1)) }
    delete api_v1_client_path(client)
    expect(response).to have_http_status(:no_content)
    expect(client.reload).to be_discarded
  end
end
