require "rails_helper"

RSpec.describe "Session" do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company:) }

  it "signs in and returns a Bearer token with the user and company" do
    travel_to Time.zone.local(2026, 11, 2, 9, 0) do
      post api_v1_session_path, params: { email: user.email, password: "Password1!", device_name: "iPhone 16" }, as: :json
    end
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to include(token_type: "Bearer", expires_at: "2026-12-02T09:00:00+08:00")
    expect(json.dig(:data, :user, :email)).to eq(user.email)
    expect(json.dig(:data, :company, :id)).to eq(company.id)
    expect(response.headers["Set-Cookie"]).to be_nil
    expect(user.allowlisted_jwts.sole).to have_attributes(name: "iPhone 16", company_id: nil)

    get api_v1_session_path, headers: { "Authorization" => "Bearer #{json.dig(:data, :token)}" }
    expect(json.dig(:data, :user, :email)).to eq(user.email)
    expect(json[:data]).not_to have_key(:token)
  end

  it "rejects a bad, expired or other-scope token" do
    sign_in_as(user)
    token = integration_session.bearer_token

    get api_v1_session_path, headers: { "Authorization" => "Bearer #{token}x" }
    expect(response).to have_http_status(:unauthorized)

    get api_v1_session_path, headers: { "Authorization" => "Token #{token}" }
    expect(response).to have_http_status(:unauthorized)

    travel 31.days do
      get api_v1_session_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "stops a suspended user's tokens" do
    sign_in_as(user)
    user.update!(status: :suspended)
    get api_v1_session_path
    expect(response).to have_http_status(:unauthorized)
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

  it "signs out this device only" do
    sign_in_as(user)
    phone = integration_session.bearer_token
    sign_in_as(user)

    delete api_v1_session_path, as: :json
    expect(response).to have_http_status(:no_content)
    get api_v1_session_path, as: :json
    expect(response).to have_http_status(:unauthorized)

    get api_v1_session_path, headers: { "Authorization" => "Bearer #{phone}" }
    expect(response).to have_http_status(:ok)
    expect(user.allowlisted_jwts.count).to eq(1)
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

      # the pick belongs to this sign-in: another device starts with no company
      sign_in_as(convoy)
      expect(json.dig(:data, :company)).to be_nil
    end

    it "is not allowed for company users" do
      sign_in_as(user)
      patch api_v1_session_path, params: { company_id: company.id }, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
