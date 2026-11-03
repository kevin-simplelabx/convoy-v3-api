require "rails_helper"

# Convoy Admin: Transport Companies (new company with its admin, counts, caps and add-ons) and Message Terms.
RSpec.describe "Convoy Admin" do
  let!(:company) { create(:company, name: "SimpleDrive") }
  let!(:owner) { create(:user, :owner, company:, email: "ops@simpledrive.sg") }

  before { sign_in_as(create(:user, :convoy_admin, name: "Convoy Admin")) }

  it "creates a company with its admin and lists companies with counts" do
    post api_v1_companies_path, params: { company: { name: "Eastern Coaches" }, admin: { name: "Mr Goh", email: "goh@eastern.sg", password: "short" } }, as: :json
    expect(json.dig(:error, :message)).to eq("Password needs at least 8 characters")
    post api_v1_companies_path, params: { company: { name: "Eastern Coaches" }, admin: { name: "Mr Goh", email: "goh@eastern.sg", password: "Eastern123!" } }, as: :json
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(name: "Eastern Coaches", code: "EC", admin: { name: "Mr Goh", email: "goh@eastern.sg" }, users_count: 1, is_current: false)
    id = json.dig(:data, :id)

    patch api_v1_company_path(id), params: { company: { external_vehicle_cap: 25, school_run_enabled: false } }, as: :json
    expect(json[:data]).to include(external_vehicle_cap: 25, school_run_enabled: false)

    patch api_v1_session_path, params: { company_id: company.id }, as: :json
    get api_v1_companies_path
    expect(json[:data].find { |c| c[:name] == "SimpleDrive" }).to include(is_current: true, admin: { name: owner.name, email: "ops@simpledrive.sg" })
  end

  it "keeps the message terms" do
    post api_v1_message_terms_path, params: { message_term: { term: " Combi ", means: "13-seater minibus", kind: "veh" } }, as: :json
    expect(json[:data]).to include(term: "Combi", kind_label: "Vehicle", created_by: "Convoy Admin")
    post api_v1_message_terms_path, params: { message_term: { term: "combi", means: "x", kind: "veh" } }, as: :json
    expect(json.dig(:error, :details, :term)).to eq([ "Term is already on the list" ])
    id = MessageTerm.find_by(term: "Combi").id
    patch api_v1_message_term_path(id), params: { message_term: { means: "13-seater" } }, as: :json
    expect(json[:data]).to include(means: "13-seater")
    get api_v1_message_terms_path
    expect(json[:meta][:kinds]).to include(veh: "Vehicle")
  end

  it "groups company leads by domain and keeps the follow-up" do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    3.times { |i| CompanyLead.create!(domain: "acme.com.sg", company_name: i.zero? ? "Acme Logistics Pte Ltd" : "Acme Logistics", asked_at: i.days.ago, contact: i == 1 ? "Jason, jason@acme.com.sg" : nil) }
    CompanyLead.create!(domain: "beta.sg", company_name: "Beta", asked_at: 1.day.ago, named_name: "Ann", named_via: "WhatsApp")
    get api_v1_leads_path
    expect(json[:data].first).to include(domain: "acme.com.sg", company: "Acme Logistics", status: "new", contacts_given: 1)
    expect(json[:data].first[:asks].size).to eq(3)

    patch api_v1_lead_path("beta.sg"), params: { status: "signed", note: "Signed 2 Nov" }, as: :json
    expect(json[:data]).to include(status: "signed", status_label: "Signed Up", note: "Signed 2 Nov", updated_by: "Convoy Admin")
    get api_v1_leads_path, params: { tab: "signed" }
    expect(json[:data].pluck(:domain)).to eq([ "beta.sg" ])
    expect(json[:meta][:counts]).to eq(open: 1, signed: 1, lost: 0)
  end

  it "is closed to company users" do
    sign_in_as(owner)
    get api_v1_message_terms_path
    expect(response).to have_http_status(:forbidden)
  end
end
