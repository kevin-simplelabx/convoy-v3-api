require "rails_helper"

# Convoy App sign-in: SG mobile or email → one-time code (always 123456 for now) → token; the first code creates the
# account, which must finish Create Your Account (name, Show My Name As, Terms) before anything else; several phones.
RSpec.describe "Convoy App sign-in" do
  def sign_in(**target) = post(api_v1_convoy_app_session_path, params: target.merge(code: "123456"), as: :json)
  def ask_code(**target) = post(code_api_v1_convoy_app_session_path, params: target, as: :json)

  it "asks for a code for a Singapore mobile or an email and refuses anything else" do
    ask_code(mobile: "9188 2045")
    expect(json[:data]).to eq(kind: "mobile", value: "+6591882045", display: "+65 9188 2045")
    ask_code(email: " Rachel@Gmail.com ")
    expect(json[:data]).to eq(kind: "email", value: "rachel@gmail.com", display: "rachel@gmail.com")

    ask_code(mobile: "1234 5678")
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Enter an 8-digit Singapore mobile number")
    ask_code(email: "not-an-email")
    expect(json.dig(:error, :message)).to eq("Enter a valid email address")
    post code_api_v1_convoy_app_session_path, params: {}, as: :json
    expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_content)
  end

  it "signs up by mobile: needs_profile → 403 profile_required → Create Your Account" do
    ask_code(mobile: "9188 2045")
    sign_in(mobile: "+65 9188 2045")
    expect(response).to have_http_status(:ok), json.inspect
    data = json[:data]
    expect(data).to include(token_type: "Bearer", token: be_present, expires_at: be_present)
    expect(data[:account]).to include(profile_complete: false, needs_identity: false, display_name: nil)
    expect(data[:account][:identities].map { it.slice(:kind, :tag, :value) }).to eq([ { kind: "mobile", tag: "personal", value: "+6591882045" } ])
    token = data[:token]

    get api_v1_convoy_app_profile_path, headers: app_as(token)
    expect(response).to have_http_status(:ok)
    post api_v1_convoy_app_company_suggestions_path, params: { identity_id: 1, company_name: "X" }, headers: app_as(token), as: :json
    expect(response).to have_http_status(:forbidden)
    expect(json[:error]).to include(code: "profile_required", message: "Create your account first")

    patch api_v1_convoy_app_profile_path, params: { profile: { first_name: "Rachel", last_name: "Tan" } }, headers: app_as(token), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :details)).to eq(accept_terms: [ "must be accepted" ])

    patch api_v1_convoy_app_profile_path, params: { profile: { first_name: "Rachel", last_name: " ", accept_terms: true } }, headers: app_as(token), as: :json
    expect(json.dig(:error, :details)).to eq(last_name: [ "can't be blank" ])

    patch api_v1_convoy_app_profile_path, params: { profile: { first_name: " Rachel ", last_name: "Tan", name_order: "last", accept_terms: true } },
                                          headers: app_as(token), as: :json
    expect(response).to have_http_status(:ok), json.inspect
    expect(json[:data]).to include(first_name: "Rachel", last_name: "Tan", name_order: "last", display_name: "Tan Rachel", profile_complete: true)
    expect(AppAccount.last.terms_accepted_at).to be_present

    get api_v1_convoy_app_session_path, headers: app_as(token)
    expect(json.dig(:data, :account, :profile_complete)).to be(true)
  end

  it "refuses an invalid Show My Name As" do
    token = app_token(mobile: "9188 2045")
    patch api_v1_convoy_app_profile_path, params: { profile: { first_name: "A", last_name: "B", name_order: "middle", accept_terms: true } },
                                          headers: app_as(token), as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "signs up by email: a work domain is a work email, a personal provider is personal" do
    app_token(email: "priya@google.com")
    expect(json.dig(:data, :account, :identities).map { it.slice(:kind, :tag, :value) }).to eq([ { kind: "email", tag: "work", value: "priya@google.com" } ])
    app_token(email: "Rachel@Gmail.com")
    expect(json.dig(:data, :account, :identities).map { it.slice(:kind, :tag, :value) }).to eq([ { kind: "email", tag: "personal", value: "rachel@gmail.com" } ])
    expect(AppAccount.count).to eq(2)
  end

  it "signs in to the same account with any of its identities, however typed" do
    account = create(:app_account, mobile: "+6591882045", email: "rachel@gmail.com")
    app_token(mobile: "9188 2045")
    expect(json.dig(:data, :account, :id)).to eq(account.id)
    expect(json.dig(:data, :account, :profile_complete)).to be(true)
    app_token(email: "RACHEL@gmail.com")
    expect(json.dig(:data, :account, :id)).to eq(account.id)
    expect(AppAccount.count).to eq(1)
    expect(account.reload.last_sign_in_at).to be_present
  end

  it "needs a code that was asked for, and that is right, and that is used once" do
    sign_in(mobile: "9188 2045")
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")

    ask_code(mobile: "9188 2045")
    post api_v1_convoy_app_session_path, params: { mobile: "9188 2045", code: "000000" }, as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(json[:error]).to include(message: "That code is not right. Try again", details: { code: [ "is not right" ] })

    sign_in(mobile: "9188 2045")
    expect(response).to have_http_status(:ok)
    sign_in(mobile: "9188 2045")
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
    expect(AppAccount.count).to eq(1)
  end

  it "expires the code after 5 wrong tries, even for the right code" do
    ask_code(mobile: "9188 2045")
    5.times { post api_v1_convoy_app_session_path, params: { mobile: "9188 2045", code: "111111" }, as: :json }
    expect(json.dig(:error, :message)).to eq("That code is not right. Try again")
    sign_in(mobile: "9188 2045")
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
    expect(AppAccount.count).to eq(0)
  end

  it "expires the code after 10 minutes" do
    ask_code(mobile: "9188 2045")
    travel 11.minutes
    sign_in(mobile: "9188 2045")
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
  end

  it "keeps a person signed in on several phones, and signing out ends only that phone" do
    phone_one = app_token(mobile: "9188 2045", device: "Pixel 8")
    phone_two = app_token(mobile: "9188 2045", device: "iPhone")
    expect(AppJwt.order(:id).map(&:name)).to eq([ "Pixel 8", "iPhone" ])

    delete api_v1_convoy_app_session_path, headers: app_as(phone_one)
    expect(response).to have_http_status(:no_content)
    get api_v1_convoy_app_session_path, headers: app_as(phone_one)
    expect(response).to have_http_status(:unauthorized)
    get api_v1_convoy_app_session_path, headers: app_as(phone_two)
    expect(response).to have_http_status(:ok)
  end

  it "refuses no token, a made-up token and an expired sign-in" do
    get api_v1_convoy_app_session_path
    expect(response).to have_http_status(:unauthorized)
    get api_v1_convoy_app_session_path, headers: app_as("nope")
    expect(response).to have_http_status(:unauthorized)

    token = app_token(mobile: "9188 2045")
    AppJwt.update_all(exp: 1.minute.ago)
    get api_v1_convoy_app_session_path, headers: app_as(token)
    expect(response).to have_http_status(:unauthorized)
  end

  it "keeps a sign-in code for one purpose from working for another" do
    account, token = app_user
    post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com" }, headers: app_as(token), as: :json
    # a verify code exists for the email; signing in with that email must not use it
    sign_in(email: "rachel@gmail.com")
    expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
    expect(account.identities.count).to eq(1)
  end
end
