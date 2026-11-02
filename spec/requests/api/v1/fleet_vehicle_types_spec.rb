require "rails_helper"

# Fleet > Vehicle Types (counts, Request a New Type, Convoy Admin decisions) and Bus Attendants.
RSpec.describe "Vehicle types page and attendants" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:admin) { create(:user, :admin, company:) }
  let!(:minibus) { create(:vehicle_type, key: "minibus_13", name: "Minibus", seats: 13) }

  before do
    within_tenant(company) do
      create(:vehicle, seats: 13)
      create(:vehicle, seats: 13, operator: create(:operator))
      create(:vehicle, seats: 45)
    end
  end

  it "counts own and operator buses by seats, with the tyre layouts" do
    sign_in_as(admin)
    get api_v1_vehicle_types_path
    expect(json[:data].first).to include(key: "minibus_13", own_count: 1, operator_count: 1, custom: false,
                                         tyre_text: "2 axles, 1 tyre each side (4 tyres)", enabled: true)
    expect(json.dig(:meta, :tyre_layouts)).to include("1-2": "2 axles, front 1 and rear 2 each side (6 tyres)")
  end

  it "sends a request that Convoy adds for every company, or declines" do
    sign_in_as(admin)
    post api_v1_vehicle_type_requests_path, params: { vehicle_type_request: { name: "minibus", seats: 13 } }, as: :json
    expect(json.dig(:error, :details, :name)).to eq([ "Name minibus 13 seats is already listed. Turn it on above" ])

    post api_v1_vehicle_type_requests_path, params: { vehicle_type_request: { name: "Luxury Coach", seats: 27, reason: "VIP client" } }, as: :json
    expect(json[:data]).to include(status: "pending", status_label: "Waiting for Convoy", requested_by: admin.name, company: { id: company.id, name: "SimpleDrive" })
    lux = json.dig(:data, :id)
    post api_v1_vehicle_type_requests_path, params: { vehicle_type_request: { name: "Party Bus", seats: 30 } }, as: :json
    party = json.dig(:data, :id)

    patch approve_api_v1_vehicle_type_request_path(lux)
    expect(response).to have_http_status(:forbidden)

    other = create(:company)
    VehicleTypeRequest.create!(company: other, name: "Other", seats: 5)

    sign_in_as(create(:user, :convoy_admin))
    get api_v1_vehicle_type_requests_path
    expect(json[:data].size).to eq(3)

    patch approve_api_v1_vehicle_type_request_path(lux), params: { tyre_layout: "1-2" }, as: :json
    expect(json[:data]).to include(status: "added", status_label: "Added")
    type = VehicleType.find(json.dig(:data, :vehicle_type_id))
    expect(type).to have_attributes(key: "luxury_coach_27", name: "Luxury Coach", seats: 27, custom: true, tyre_layout: "1-2")

    patch decline_api_v1_vehicle_type_request_path(party)
    expect(json[:data][:status]).to eq("declined")

    delete api_v1_vehicle_type_path(minibus)
    expect(json.dig(:error, :message)).to eq("Built-in types can't be removed. Companies turn them off instead")
    delete api_v1_vehicle_type_path(type)
    expect(response).to have_http_status(:no_content)

    sign_in_as(admin)
    get api_v1_vehicle_type_requests_path
    expect(json[:data].pluck(:name)).to eq([ "Party Bus", "Luxury Coach" ])
  end

  it "keeps bus attendants with contact and notes" do
    sign_in_as(admin)
    post api_v1_attendants_path, params: { attendant: { name: "Mdm Rosnah", phone: "+65 9111 2233", notes: "Bedok, Malay" } }, as: :json
    id = json.dig(:data, :id)
    patch api_v1_attendant_path(id), params: { attendant: { notes: "Bedok, Malay, Tamil" } }, as: :json
    expect(json[:data]).to include(name: "Mdm Rosnah", notes: "Bedok, Malay, Tamil")
    delete api_v1_attendant_path(id)
    get api_v1_attendants_path
    expect(json[:data]).to be_empty
  end
end
