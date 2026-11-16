# Convoy App request specs: sign a mobile / email in with the fixed code and send its token on a call.
module ConvoyAppHelpers
  # Token of the account that owns `mobile:` / `email:` (the account is created by the first sign-in). Clears any other
  # app's bearer so the example sends only what it passes.
  def app_token(mobile: nil, email: nil, device: "Pixel 8")
    integration_session.bearer_token = nil
    target = mobile ? { mobile: } : { email: }
    post code_api_v1_convoy_app_session_path, params: target, as: :json
    post api_v1_convoy_app_session_path, params: target.merge(code: "123456", device_name: device), as: :json
    expect(response).to have_http_status(:ok), json.inspect
    json.dig(:data, :token)
  end

  def app_as(token) = { "Authorization" => "Bearer #{token}" }

  # A signed-in account with Create Your Account done; returns [account, token].
  def app_user(mobile: "9188 2045", name: %w[Rachel Tan])
    token = app_token(mobile:)
    patch api_v1_convoy_app_profile_path, params: { profile: { first_name: name[0], last_name: name[1], accept_terms: true } },
                                           headers: app_as(token), as: :json
    expect(response).to have_http_status(:ok), json.inspect
    [ AppAccount.find(json.dig(:data, :id)), token ]
  end

  # Add Mobile / Email: both steps; the caller checks the response.
  def app_add_identity(token, kind:, value:, tag: "personal", replace: false)
    post code_api_v1_convoy_app_identities_path, params: { kind:, value:, tag:, replace: }, headers: app_as(token), as: :json
    return unless response.successful?

    post verify_api_v1_convoy_app_identities_path, params: { kind:, value:, tag:, replace:, code: "123456" }, headers: app_as(token), as: :json
  end
end

RSpec.configure { it.include ConvoyAppHelpers, type: :request }
