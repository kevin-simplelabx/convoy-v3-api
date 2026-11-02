require "rails_helper"

RSpec.describe "Companies" do
  let!(:company) { create(:company, name: "SimpleDrive") }
  let!(:other) { create(:company, name: "Other Co") }

  context "as a company admin" do
    let(:user) { create(:user, :admin, company:) }
    before { sign_in_as(user) }

    it "lists only their own company" do
      get api_v1_companies_path, as: :json
      expect(json[:data].pluck(:id)).to eq([ company.id ])
      expect(json[:meta]).to include(count: 1, page: 1)
    end

    it "cannot open another company" do
      get api_v1_company_path(other), as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "updates settings but not platform fields" do
      patch api_v1_company_path(company), params: { company: { short_name: "SD", external_vehicle_cap: 99 } }, as: :json
      expect(response).to have_http_status(:ok)
      expect(company.reload).to have_attributes(short_name: "SD", external_vehicle_cap: 10)
    end

    it "returns validation errors" do
      patch api_v1_company_path(company), params: { company: { theme_color: "teal" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :details)).to have_key(:theme_color)
    end
  end

  context "as a member" do
    it "cannot change settings" do
      sign_in_as(create(:user, company:))
      patch api_v1_company_path(company), params: { company: { short_name: "X" } }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "as Convoy Admin" do
    before { sign_in_as(create(:user, :convoy_admin)) }

    it "lists every company with platform fields" do
      get api_v1_companies_path, params: { q: { name_i_cont: "simple" } }
      expect(json[:data].pluck(:id)).to eq([ company.id ])
      expect(json[:data].first).to have_key(:external_vehicle_cap)
    end

    it "creates a company and sets platform fields" do
      post api_v1_companies_path, params: { company: { name: "New Co", code: "nc", external_vehicle_cap: 20 } }, as: :json
      expect(response).to have_http_status(:created)
      expect(Company.find(json.dig(:data, :id))).to have_attributes(code: "NC", external_vehicle_cap: 20)
    end
  end
end
