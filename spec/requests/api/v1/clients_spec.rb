require "rails_helper"

RSpec.describe "Clients" do
  let(:company) { create(:company) }

  before { sign_in_as(create(:user, company:)) }

  it "adds a client from the trip form, then sites and end customers" do
    post api_v1_clients_path, params: { client: { name: "Eastern Coaches", kind: "transport_company" } }, as: :json
    expect(response).to have_http_status(:created)
    id = json.dig(:data, :id)
    expect(json.dig(:data, :code)).to eq("CL00001")

    post api_v1_client_sites_path(id), params: { client_site: { name: "HQ", lat: 1.3, lng: 103.8 } }, as: :json
    post api_v1_client_end_customers_path(id), params: { client_end_customer: { name: "Mapletree" } }, as: :json
    expect(response).to have_http_status(:created)

    get api_v1_client_path(id)
    expect(json.dig(:data, :sites).pluck(:name)).to eq(%w[HQ])
    expect(json.dig(:data, :end_customers).pluck(:name)).to eq(%w[Mapletree])
  end

  it "searches by name" do
    within_tenant(company) { %w[Google DBS].each { |n| create(:client, name: n) } }
    get api_v1_clients_path, params: { q: { name_i_cont: "goo" } }
    expect(json[:data].pluck(:name)).to eq(%w[Google])
  end

  it "ignores a bare q string instead of failing" do
    within_tenant(company) { %w[Google DBS].each { |n| create(:client, name: n) } }
    get api_v1_clients_path, params: { q: "Google" }
    expect(response).to have_http_status(:ok)
    expect(json[:data].pluck(:name)).to eq(%w[DBS Google])
  end
end
