require "rails_helper"

RSpec.describe "Session" do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company:) }

  it "signs in and returns the user and company" do
    sign_in_as(user)
    expect(json.dig(:data, :user, :email)).to eq(user.email)
    expect(json.dig(:data, :company, :id)).to eq(company.id)
  end

  it "rejects a wrong password" do
    post api_v1_session_path, params: { email: user.email, password: "wrong" }, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(json.dig(:error, :message)).to eq("Email or password is incorrect")
  end

  it "rejects a suspended user" do
    suspended = create(:user, :suspended)
    post api_v1_session_path, params: { email: suspended.email, password: "Password1!" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 401 when not signed in" do
    get api_v1_session_path, as: :json
    expect(response).to have_http_status(:unauthorized)
    expect(json[:error]).to include(code: "unauthorized")
  end

  it "signs out" do
    sign_in_as(user)
    delete api_v1_session_path, as: :json
    expect(response).to have_http_status(:no_content)
    get api_v1_session_path, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  describe "Convoy Admin company switch" do
    let(:convoy) { create(:user, :convoy_admin) }

    it "starts with no company and can pick one" do
      sign_in_as(convoy)
      expect(json.dig(:data, :company)).to be_nil

      patch api_v1_session_path, params: { company_id: company.id }, as: :json
      expect(json.dig(:data, :company, :id)).to eq(company.id)

      get api_v1_session_path, as: :json
      expect(json.dig(:data, :company, :id)).to eq(company.id)
    end

    it "is not allowed for company users" do
      sign_in_as(user)
      patch api_v1_session_path, params: { company_id: company.id }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
