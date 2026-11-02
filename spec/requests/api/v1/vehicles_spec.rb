require "rails_helper"

RSpec.describe "Vehicles" do
  let(:company) { create(:company, external_vehicle_cap: 1) }
  let(:admin) { create(:user, :admin, company:) }
  let!(:fleet) do
    within_tenant(company) do
      managed = create(:operator, name: "Hup Seng")
      {
        van: create(:vehicle, plate: "PD1A", seats: 13, tags: %w[VIP]),
        coach: create(:vehicle, plate: "PD2B", seats: 45, tags: %w[Coach], operator: managed),
        car: create(:vehicle, plate: "PD3C", seats: 4, make: "Toyota", model: "Camry")
      }
    end
  end

  before { sign_in_as(admin) }

  it "lists by type with facets" do
    get api_v1_vehicles_path
    expect(json[:data].pluck(:plate)).to eq(%w[PD3C PD1A PD2B])
    expect(json.dig(:meta, :facets)).to include(
      ownership: { own: 2, managed: 1, external: 0 }, vip: 1, tags: { Coach: 1 }
    )
    expect(json[:data].first).to include(ownership: "own", size: "sedan", default_picture: "sedan-4", model: "Camry")
  end

  it "filters by size, ownership, tags, VIP and search" do
    get api_v1_vehicles_path, params: { size: %w[small large], ownership: %w[own] }
    expect(json[:data].pluck(:plate)).to eq(%w[PD1A])

    get api_v1_vehicles_path, params: { vip: true }
    expect(json[:data].pluck(:plate)).to eq(%w[PD1A])

    get api_v1_vehicles_path, params: { q: "hup" }
    expect(json[:data].pluck(:plate)).to eq(%w[PD2B])

    get api_v1_vehicles_path, params: { sort: "largest", tags: %w[Coach] }
    expect(json[:data].pluck(:plate)).to eq(%w[PD2B])
  end

  it "shows today's default driver" do
    within_tenant(company) do
      fleet[:van].driver_schedules.create!(driver: create(:driver, name: "Eric Pang"), starts_on: Date.current - 1)
    end
    get api_v1_vehicle_path(fleet[:van])
    expect(json.dig(:data, :driver)).to include(kind: "own", name: "Eric Pang")
  end

  it "creates with tags as text and soft deletes" do
    post api_v1_vehicles_path, params: { vehicle: { plate: "pe 1290 s", seats: 45, tags: "Coach, Wheelchair" } }, as: :json
    expect(response).to have_http_status(:created)
    expect(json[:data]).to include(plate: "PE1290S", tags: %w[Coach Wheelchair])

    delete api_v1_vehicle_path(json.dig(:data, :id))
    expect(response).to have_http_status(:no_content)
    expect(Vehicle.unscoped.find_by(plate: "PE1290S").discarded_at).to be_present
  end

  it "uploads a photo through CarrierWave" do
    photo = fixture_file_upload(Rails.root.join("db/seeds/files/fleet/van.png"), "image/png")
    patch api_v1_vehicle_path(fleet[:van]), params: { vehicle: { photo: } }
    expect(json.dig(:data, :photo, :thumb_url)).to start_with("/api/v1/downloads/")

    get json.dig(:data, :photo, :url)
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/png")
  end

  describe "external vehicle" do
    it "creates the bus and its company, then stops at the cap" do
      post external_api_v1_vehicles_path,
           params: { plate: "PA1234X", seats: 45, driver_name: "Muthu", company: { name: "Kallang Bus", paynow_uen: "201912345K" } }, as: :json
      expect(response).to have_http_status(:created)
      expect(json[:data]).to include(ownership: "external", driver_name: "Muthu")
      expect(json.dig(:data, :operator, :name)).to eq("Kallang Bus")

      post external_api_v1_vehicles_path, params: { plate: "PA9", company: { name: "kallang bus" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to start_with("All 1 external vehicle slots are used")
      expect(Operator.unscoped.where(company:, kind: :external).count).to eq(1)
    end
  end

  describe "access" do
    it "hides other companies' vehicles" do
      other = create(:company)
      within_tenant(other) { create(:vehicle, plate: "ZZ1") }
      get api_v1_vehicles_path
      expect(json[:data].pluck(:plate)).not_to include("ZZ1")
    end

    it "needs the vehicles permission to change the fleet" do
      sign_in_as(create(:user, company:, permissions: %w[finance]))
      post api_v1_vehicles_path, params: { vehicle: { plate: "X1" } }, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "lets Convoy Admin view but not change" do
      sign_in_as(create(:user, :convoy_admin))
      patch api_v1_session_path, params: { company_id: company.id }, as: :json
      get api_v1_vehicles_path
      expect(json[:data].size).to eq(3)
      post api_v1_vehicles_path, params: { vehicle: { plate: "X1" } }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(json.dig(:error, :message)).to start_with("View only")
    end
  end
end
