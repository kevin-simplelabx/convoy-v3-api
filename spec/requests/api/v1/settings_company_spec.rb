require "rails_helper"

# Company Settings: who can edit, logo, the country picked once then locked, and Request a Country Change.
RSpec.describe "Company settings" do
  let(:company) { create(:company, name: "SimpleDrive Pte Ltd") }
  let(:editor) { create(:user, company:, name: "Uma Users", permissions: %w[users]) }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    allow(Country).to receive(:live_codes).and_return(%w[SG MY])
  end

  it "lists the countries" do
    sign_in_as(editor)
    get api_v1_countries_path
    expect(json[:data].first).to include(code: "SG", name: "Singapore", live: true, currency: "SGD", map: "OneMap")
    expect(json[:data].pluck(:code)).to eq(%w[SG TW MY TH HK])
  end

  it "lets a user with the Users permission edit, others only view" do
    sign_in_as(create(:user, company:, permissions: %w[vehicles]))
    get api_v1_company_path(company)
    expect(json[:data]).to include(can_edit: false, country_locked: false)
    patch api_v1_company_path(company), params: { company: { short_name: "SD" } }, as: :json
    expect(response).to have_http_status(:forbidden)

    sign_in_as(editor)
    patch api_v1_company_path(company), params: { company: { name: "Renamed", short_name: "SD", time_format: "12", date_format: "dmon",
                                                             logo: fixture_file_upload("photo.png", "image/png") } }
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(name: "SimpleDrive Pte Ltd", short_name: "SD", time_format: "12", date_format: "dmon", can_edit: true)
    expect(json.dig(:data, :logo, :url)).to be_present

    patch api_v1_company_path(company), params: { company: { remove_logo: true } }, as: :json
    expect(json.dig(:data, :logo)).to be_nil
  end

  it "picks the country once, then locks it" do
    sign_in_as(editor)
    patch api_v1_company_path(company), params: { company: { country: "TW" } }, as: :json
    expect(json.dig(:error, :details, :country)).to eq([ "Country is not open yet" ])

    patch api_v1_company_path(company), params: { company: { country: "MY" } }, as: :json
    expect(json[:data]).to include(country: "MY", country_locked: true, country_set_by: { id: editor.id, name: "Uma Users" })

    patch api_v1_company_path(company), params: { company: { country: "SG" } }, as: :json
    expect(company.reload.country).to eq("MY")
  end

  it "requests a change that Convoy approves, declines, or the company withdraws" do
    company.update!(country_set_at: 1.year.ago)
    sign_in_as(editor)
    post api_v1_country_requests_path, params: { country_request: { to_country: "SG", reason: "" } }, as: :json
    expect(json.dig(:error, :details)).to include(to_country: [ "To country is where the company is already (Singapore)" ], reason: [ "Reason can't be blank" ])

    post api_v1_country_requests_path, params: { country_request: { to_country: "my", reason: "Moving to KL" } }, as: :json
    expect(response).to have_http_status(:created)
    expect(json[:data]).to include(from_country: "SG", to_country: "MY", to_country_name: "Malaysia", status: "pending",
                                   requested_by: { id: editor.id, name: "Uma Users" })
    first = json.dig(:data, :id)

    post api_v1_country_requests_path, params: { country_request: { to_country: "MY", reason: "Again" } }, as: :json
    expect(json.dig(:error, :details, :base)).to eq([ "A change is already waiting for Convoy" ])
    get api_v1_company_path(company)
    expect(json.dig(:data, :country_request)).to include(id: first, status: "pending")

    post withdraw_api_v1_country_request_path(first)
    expect(json[:data]).to include(status: "withdrawn")

    post api_v1_country_requests_path, params: { country_request: { to_country: "MY", reason: "Moving to KL" } }, as: :json
    second = json.dig(:data, :id)
    post approve_api_v1_country_request_path(second)
    expect(response).to have_http_status(:forbidden)

    convoy = create(:user, :convoy_admin)
    sign_in_as(convoy)
    get api_v1_country_requests_path, params: { status: "pending" }
    expect(json[:data].pluck(:id, :company_name)).to eq([ [ second, "SimpleDrive Pte Ltd" ] ])
    post approve_api_v1_country_request_path(second)
    expect(json[:data]).to include(status: "approved", decided_by: { id: convoy.id, name: convoy.name })
    expect(company.reload).to have_attributes(country: "MY", country_set_by_id: convoy.id)

    sign_in_as(editor)
    post api_v1_country_requests_path, params: { country_request: { to_country: "SG", reason: "Back home" } }, as: :json
    third = json.dig(:data, :id)
    sign_in_as(convoy)
    post decline_api_v1_country_request_path(third)
    expect(json[:data]).to include(status: "declined")
    expect(company.reload.country).to eq("MY")
  end
end
