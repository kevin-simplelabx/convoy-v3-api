require "rails_helper"

# Fleet > External Vehicles: slots used against the cap, edit with company details, the Share Form.
RSpec.describe "External vehicles and the Share Form" do
  let(:company) { create(:company, name: "SimpleDrive", external_vehicle_cap: 2) }
  let(:admin) { create(:user, :admin, company:) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(admin)
  end

  def add(plate, **extra)
    post external_api_v1_vehicles_path, params: { plate:, seats: 45, driver_name: "Muthu", driver_phone: "+65 9123 4567",
                                                  company: { name: "Kallang Bus" } }.merge(extra), as: :json
  end

  it "shows the slots used and keeps company details shared by its buses" do
    add("PA1X", company: { name: "Kallang Bus", phone: "+65 6222 3333", paynow_uen: "201912345K",
                           cost_per_trip: 180, cost_per_day: 650, valid_until: "2026-12-31" })
    expect(response).to have_http_status(:created), json.inspect
    get api_v1_vehicles_path, params: { ownership: %w[external] }
    expect(json.dig(:meta, :external_cap)).to eq(used: 1, limit: 2, left: 1)
    expect(json[:data].first).to include(plate: "PA1X", source: "console")
    expect(json.dig(:data, 0, :operator)).to include(name: "Kallang Bus", cost_per_trip: "180.0", valid_until: "2026-12-31")
  end

  it "takes a hired driver's answer from the public link, then Review and Add or Dismiss" do
    get api_v1_external_share_link_path
    token = json.dig(:data, :token)
    expect(json.dig(:data, :api_path)).to eq("/api/v1/public/share_forms/#{token}")
    get api_v1_external_share_link_path
    expect(json.dig(:data, :token)).to eq(token)

    delete api_v1_session_path
    get api_v1_public_share_form_path(token)
    expect(json[:data]).to eq(company: "SimpleDrive")

    post api_v1_public_share_form_path(token), params: { submission: { plate: "pa 77 z", driver_name: "", driver_phone: "123", company_name: "Kallang" } }, as: :json
    expect(json[:error]).to include(message: "Enter your name", details: { driver_name: [ "Enter your name" ], driver_phone: [ "Enter your mobile number" ] })

    post api_v1_public_share_form_path(token), params: { submission: { plate: "pa 77 z", seats: 40, driver_name: "Ali", driver_phone: "91234567",
                                                                      company_name: "Kallang Bus", paynow: "201912345K" } }, as: :json
    expect(response).to have_http_status(:created)
    post api_v1_public_share_form_path(token), params: { submission: { plate: "PB1", driver_name: "Ben", driver_phone: "92223333", company_name: "Other" } }, as: :json

    sign_in_as(admin)
    get api_v1_external_vehicle_submissions_path
    expect(json[:data].pluck(:plate)).to eq(%w[PB1 PA77Z])
    ali, ben = json[:data].last, json[:data].first

    add("PA77Z", submission_id: ali[:id], driver_name: "Ali")
    expect(json[:data]).to include(source: "share_form")
    patch dismiss_api_v1_external_vehicle_submission_path(ben[:id])
    expect(json[:data][:status]).to eq("dismissed")

    get api_v1_external_vehicle_submissions_path
    expect(json[:data]).to be_empty
    get api_v1_external_vehicle_submissions_path, params: { status: "added" }
    expect(json[:data].first).to include(plate: "PA77Z", vehicle_id: Vehicle.unscoped.find_by(plate: "PA77Z").id)

    # A new link: the old one stops working
    post reset_api_v1_external_share_link_path
    expect(json.dig(:data, :token)).not_to eq(token)
    get api_v1_public_share_form_path(token)
    expect(response).to have_http_status(:not_found)
    expect(json.dig(:error, :message)).to eq("This link no longer works. Ask for a new one")
  end
end
