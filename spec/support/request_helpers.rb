module RequestHelpers
  def json
    response.parsed_body.deep_symbolize_keys
  end

  # Signs in and sends the Bearer token with every later request of the example (like the apps do).
  def sign_in_as(user, password: "Password1!")
    post api_v1_session_path, params: { email: user.email, password: }, as: :json
    expect(response).to have_http_status(:ok)
    integration_session.bearer_token = json.dig(:data, :token)
  end

  module BearerHeader
    attr_accessor :bearer_token

    def process(method, path, params: nil, headers: nil, **)
      headers = { "Authorization" => "Bearer #{bearer_token}" }.merge(headers || {}) if bearer_token
      super
    end
  end
end

ActionDispatch::Integration::Session.prepend(RequestHelpers::BearerHeader)

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
