require "rails_helper"

# School Bus › Schools: list (only the user's schools), New School placed by OneMap (cached), Route Labels.
RSpec.describe "School Bus schools" do
  let(:company) { create(:company) }
  let!(:sss) { within_tenant(company) { School.create!(name: "St. Stephen's School", short_name: "SSS", postal: "455789") } }
  let!(:other) { within_tenant(company) { School.create!(name: "Nanyang Primary") } }

  before { fake_one_map.add("455789", 1.3138, 103.9283, "20 Siglap View") }

  it "adds a school placed by its postal code, once per code" do
    sign_in_as(create(:user, company:, permissions: %w[schools]))
    post api_v1_schools_path, params: { school: { name: "Opera Estate Primary", short_name: "OEPS", postal: "455 789" } }
    expect(response).to have_http_status(:created)
    expect(json[:data]).to include(name: "Opera Estate Primary", postal: "455789", address: "20 Siglap View", lat: 1.3138, lng: 103.9283)
    expect(json.dig(:data, :route_labels).map { |l| l[:preview].first }).to eq([ "AM 1", "PM 1", "CCA 1" ])

    post api_v1_schools_path, params: { school: { name: "Another", postal: "455789", address: "Gate B" } }
    expect(json[:data]).to include(address: "Gate B")
    expect(fake_one_map.searches).to eq(%w[455789])

    post api_v1_schools_path, params: { school: { name: "Nowhere", postal: "999999" } }
    expect(json.dig(:error, :message)).to eq("Postal code not found on OneMap")
    post api_v1_schools_path, params: { school: { name: "Short", postal: "12345" } }
    expect(json.dig(:error, :message)).to eq("Postal code must be 6 digits")
  end

  it "saves Route Labels" do
    sign_in_as(create(:user, company:, permissions: %w[schools]))
    put route_labels_api_v1_school_path(sss), params: { labels: { am: { prefix: "", start: 1, digits: 2, suffix: "A" }, asa: { prefix: "ASA-", start: 0 } } }
    labels = json.dig(:data, :route_labels).index_by { |l| l[:session] }
    expect(labels["am"][:preview]).to eq(%w[01A 02A 03A])
    expect(labels["asa"][:preview]).to eq(%w[ASA-0 ASA-1 ASA-2])
    expect(labels["pm"][:preview].first).to eq("PM 1")

    put route_labels_api_v1_school_path(sss), params: { labels: { am: { digits: 5 } } }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "lists only the schools a user may open; changes need the schools permission" do
    user = create(:user, company:, permissions: %w[plans], all_schools: false)
    within_tenant(company) { UserSchool.create!(user:, school: sss) }
    sign_in_as(user)
    get api_v1_schools_path
    expect(json[:data].map { |s| s[:name] }).to eq([ "St. Stephen's School" ])
    get api_v1_school_path(other)
    expect(response).to have_http_status(:not_found)
    post api_v1_schools_path, params: { school: { name: "X", postal: "455789" } }
    expect(response).to have_http_status(:forbidden)
  end
end
