module RequestHelpers
  def json
    response.parsed_body.deep_symbolize_keys
  end

  def sign_in_as(user, password: "Password1!")
    post api_v1_session_path, params: { email: user.email, password: }, as: :json
    expect(response).to have_http_status(:ok)
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
