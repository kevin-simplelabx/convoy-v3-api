require "rails_helper"

# Convoy Driver app sign-in: mobile → one-time code (always 123456 for now) → token; the account is created by the first
# code and takes every company record with that mobile; one phone at a time; Switch Company; invitations; email sign-in.
RSpec.describe "Driver app sign-in" do
  let(:simpledrive) { create(:company, name: "SimpleDrive") }
  let(:island) { create(:company, name: "Island Coaches") }
  let!(:own) { within_tenant(simpledrive) { create(:driver, name: "Ahmad", phone: "+6591234567") } }
  let!(:managed) do
    within_tenant(simpledrive) { create(:operator_driver, name: "Ahmad R", phone: "+6591234567", status: :pending, operator: create(:operator, name: "Hup Seng")) }
  end
  let!(:invite) { within_tenant(island) { create(:driver, name: "Ahmad bin Rahman", phone: "+6591234567", status: :pending) } }

  def sign_in(phone: "9123 4567", device: "Pixel 8")
    post code_api_v1_driver_app_session_path, params: { phone: }, as: :json
    post api_v1_driver_app_session_path, params: { phone:, code: "123456", device_name: device }, as: :json
    expect(response).to have_http_status(:ok), json.inspect
    json.dig(:data, :token)
  end

  def bearer(token) = { "Authorization" => "Bearer #{token}" }

  def app_sessions = ActsAsTenant.without_tenant { DriverAppSession.order(:id).to_a }

  it "creates the account with the first code, links the company records and picks the only company" do
    post code_api_v1_driver_app_session_path, params: { phone: "12" }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter a valid mobile number")

    post code_api_v1_driver_app_session_path, params: { phone: "9123 4567" }, as: :json
    expect(json[:data]).to eq(phone: "+6591234567", phone_display: "+65 9123 4567", new_account: true)

    post api_v1_driver_app_session_path, params: { phone: "+65 9123 4567", code: "000000" }, as: :json
    expect(json.dig(:error, :message)).to eq("That code is not right. Check the SMS and try again")
    post api_v1_driver_app_session_path, params: { phone: "+65 9123 4567", code: "123456", device_name: "Pixel 8" }, as: :json
    expect(response).to have_http_status(:ok), json.inspect
    data = json[:data]
    expect(data).to include(token_type: "Bearer", account: hash_including(phone: "+6591234567", password_set: false))
    expect(data[:memberships].map { [ it[:key], it[:status], it[:kind] ] })
      .to eq([ [ "driver-#{own.id}", "active", "own" ], [ "driver-#{invite.id}", "pending", "own" ], [ "operator_driver-#{managed.id}", "pending", "managed" ] ])
    expect(data[:memberships].last).to include(employer_name: "Hup Seng", managed_by: "SimpleDrive")
    expect(data[:current]).to include(key: "driver-#{own.id}", company: hash_including(name: "SimpleDrive"))
    expect(app_sessions.map { [ it.driver_id, it.signed_out_at ] }).to eq([ [ own.id, nil ] ])

    post api_v1_driver_app_session_path, params: { phone: "91234567", code: "123456" }, as: :json
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")

    token = data[:token]
    get api_v1_driver_app_session_path, headers: bearer(token)
    expect(json.dig(:data, :current, :key)).to eq("driver-#{own.id}")
    get api_v1_scheduler_path, headers: bearer(token)
    expect(response).to have_http_status(:unauthorized)

    admin = within_tenant(simpledrive) { create(:user, :admin, company: simpledrive) }
    sign_in_as(admin)
    get api_v1_driver_app_session_path
    expect(response).to have_http_status(:unauthorized)
  end

  it "keeps one phone signed in at a time" do
    first = sign_in(device: "Old phone")
    second = sign_in(device: "New phone")

    get api_v1_driver_app_session_path, headers: bearer(first)
    expect(response).to have_http_status(:unauthorized)
    get api_v1_driver_app_session_path, headers: bearer(second)
    expect(response).to have_http_status(:ok)
    expect(app_sessions.map { it.signed_out_at.present? }).to eq([ true, false ])

    delete api_v1_driver_app_session_path, headers: bearer(second)
    expect(response).to have_http_status(:no_content)
    expect(app_sessions.last.signed_out_at).to be_present
    get api_v1_driver_app_session_path, headers: bearer(second)
    expect(response).to have_http_status(:unauthorized)
  end

  it "accepts and declines invitations, switches company and disconnects" do
    token = sign_in

    patch api_v1_driver_app_session_path, params: { membership: "operator_driver-#{managed.id}" }, headers: bearer(token), as: :json
    expect(json.dig(:error, :message)).to eq("You can only switch to a company you work for")

    post accept_api_v1_driver_app_company_path("operator_driver-#{managed.id}"), headers: bearer(token)
    expect(json[:data]).to include(status: "active", joined_at: be_present)
    get api_v1_driver_app_session_path, headers: bearer(token)
    expect(json.dig(:data, :current, :key)).to eq("driver-#{own.id}")

    post decline_api_v1_driver_app_company_path("driver-#{invite.id}"), headers: bearer(token)
    expect(json.dig(:data, :status)).to eq("declined")
    get api_v1_driver_app_companies_path, headers: bearer(token)
    expect(json[:data].pluck(:key)).to eq([ "driver-#{own.id}", "operator_driver-#{managed.id}" ])

    patch api_v1_driver_app_session_path, params: { membership: "operator_driver-#{managed.id}" }, headers: bearer(token), as: :json
    expect(json.dig(:data, :current)).to include(key: "operator_driver-#{managed.id}", employer_name: "Hup Seng")
    expect(app_sessions.map { [ it.driver_id, it.operator_driver_id, it.signed_out_at.present? ] })
      .to eq([ [ own.id, nil, true ], [ nil, managed.id, false ] ])

    post disconnect_api_v1_driver_app_company_path("operator_driver-#{managed.id}"), headers: bearer(token)
    expect(json[:data]).to include(status: "past", left_at: be_present)
    get api_v1_driver_app_session_path, headers: bearer(token)
    expect(json.dig(:data, :current)).to be_nil
    expect(json.dig(:data, :memberships).map { [ it[:key], it[:status] ] })
      .to eq([ [ "driver-#{own.id}", "active" ], [ "operator_driver-#{managed.id}", "past" ] ])
    expect(ActsAsTenant.without_tenant { managed.reload.audits.last.user }).to eq(DriverAccount.last)

    other = within_tenant(island) { create(:driver, phone: "+6598765432") }
    post accept_api_v1_driver_app_company_path("driver-#{other.id}"), headers: bearer(token)
    expect(response).to have_http_status(:not_found)
  end

  it "links a driver invited after the account exists, and signs in with email and password" do
    sign_in
    account = DriverAccount.last
    account.update!(email: "Ahmad@Mail.com", password: "Driver123!", password_confirmation: "Driver123!", password_set_at: Time.current)

    later = within_tenant(island) { create(:operator_driver, phone: "+65 9123 4567", status: :pending) }
    expect(later.driver_account).to eq(account)

    post email_api_v1_driver_app_session_path, params: { email: "ahmad@mail.com", password: "wrong" }, as: :json
    expect(response).to have_http_status(:unauthorized)
    post email_api_v1_driver_app_session_path, params: { email: " ahmad@mail.com", password: "Driver123!" }, as: :json
    expect(response).to have_http_status(:ok)
    expect(json.dig(:data, :memberships).size).to eq(4)
  end

  it "limits codes to 5 an hour per mobile" do
    5.times { post code_api_v1_driver_app_session_path, params: { phone: "91234567" }, as: :json }
    expect(response).to have_http_status(:ok)
    post code_api_v1_driver_app_session_path, params: { phone: "91234567" }, as: :json
    expect(json.dig(:error, :message)).to eq("Too many codes asked for. Try again in an hour")
  end
end
