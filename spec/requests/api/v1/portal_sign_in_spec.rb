require "rails_helper"

# Client Portal sign-in: email → one-time code (first time) → set password → token; password next time; forgot
# password; one person at several clients picks the account.
RSpec.describe "Client Portal sign-in" do
  include ActiveJob::TestHelper

  let(:company) { create(:company, name: "SimpleDrive") }
  let!(:users) do
    within_tenant(company) do
      google = create(:client, name: "Google")
      school = create(:client, name: "St. Stephen's School")
      account = PortalAccount.for_email!("priya@google.com", name: "Priya")
      { google: google.users.create!(company_id: company.id, name: "Priya", email: "priya@google.com", role: "super", portal_account: account),
        school: school.users.create!(company_id: company.id, name: "Priya", email: "priya@google.com", role: "member", portal_account: account) }
    end
  end

  around { |ex| with_show_code { ex.run } }

  def with_show_code
    old = ENV["PORTAL_SHOW_CODE"]
    ENV["PORTAL_SHOW_CODE"] = "1"
    yield
  ensure
    ENV["PORTAL_SHOW_CODE"] = old
  end

  def portal_token = json.dig(:data, :token)

  it "signs in the first time with an emailed code, then with the password" do
    post lookup_api_v1_portal_session_path, params: { email: "nobody@x.sg" }, as: :json
    expect(json.dig(:error, :message)).to start_with("No client account for this email")

    expect { post lookup_api_v1_portal_session_path, params: { email: " Priya@Google.com " }, as: :json }
      .to have_enqueued_mail(PortalMailer, :sign_in_code)
    expect(json[:data]).to include(email: "priya@google.com", next: "code", purpose: "first")
    code = json.dig(:data, :dev_code)
    expect(code).to match(/\A\d{6}\z/)

    post verify_api_v1_portal_session_path, params: { email: "priya@google.com", code: "000000" == code ? "111111" : "000000" }, as: :json
    expect(json.dig(:error, :message)).to eq("That code is not right. Check the email and try again")
    post verify_api_v1_portal_session_path, params: { email: "priya@google.com", code: }, as: :json
    set_token = json.dig(:data, :set_password_token)
    post verify_api_v1_portal_session_path, params: { email: "priya@google.com", code: }, as: :json
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")

    post api_v1_portal_password_path, params: { set_password_token: set_token, password: "short", password_confirmation: "short" }, as: :json
    expect(json.dig(:error, :details, :password)).to eq([ "Password needs at least 8 characters" ])
    post api_v1_portal_password_path, params: { set_password_token: set_token, password: "Portal123!", password_confirmation: "Portal123!" }, as: :json
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(token_type: "Bearer", account: hash_including(email: "priya@google.com"), current: nil)
    expect(json.dig(:data, :accounts).map { |a| a.dig(:client, :name) }).to eq([ "Google", "St. Stephen's School" ])
    expect(json.dig(:data, :accounts, 0)).to include(role_label: "Super Admin", company: hash_including(name: "SimpleDrive"))

    post api_v1_portal_password_path, params: { set_password_token: set_token, password: "Another123!" }, as: :json
    expect(json.dig(:error, :message)).to eq("This link has expired. Ask for a new code")

    post lookup_api_v1_portal_session_path, params: { email: "priya@google.com" }, as: :json
    expect(json[:data]).to eq(email: "priya@google.com", next: "password")
    post api_v1_portal_session_path, params: { email: "priya@google.com", password: "wrong" }, as: :json
    expect(response).to have_http_status(:unauthorized)
    post api_v1_portal_session_path, params: { email: "priya@google.com", password: "Portal123!" }, as: :json
    token = portal_token

    patch api_v1_portal_session_path, params: { client_user_id: users[:school].id }, headers: { "Authorization" => "Bearer #{token}" }, as: :json
    expect(json.dig(:data, :current)).to include(client_user_id: users[:school].id, role: "member")

    get api_v1_scheduler_path, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unauthorized)

    delete api_v1_portal_session_path, headers: { "Authorization" => "Bearer #{token}" }
    get api_v1_portal_session_path, headers: { "Authorization" => "Bearer #{token}" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "resets a forgotten password with a new code and drops removed accounts" do
    users[:google].portal_account.update!(password: "Portal123!", password_set_at: Time.current)
    post code_api_v1_portal_session_path, params: { email: "priya@google.com" }, as: :json
    expect(json[:data]).to include(next: "code", purpose: "reset")

    within_tenant(company) { ClientUsers::Remove.call(user: users[:school]) }
    post api_v1_portal_session_path, params: { email: "priya@google.com", password: "Portal123!" }, as: :json
    expect(json.dig(:data, :accounts).size).to eq(1)
    expect(json.dig(:data, :current)).to include(client_user_id: users[:google].id)
  end

  it "gives no code without PORTAL_SHOW_CODE" do
    ENV["PORTAL_SHOW_CODE"] = nil
    post lookup_api_v1_portal_session_path, params: { email: "priya@google.com" }, as: :json
    expect(json[:data]).not_to have_key(:dev_code)
  end
end
