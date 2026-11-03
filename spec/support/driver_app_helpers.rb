# Driver app request specs: sign a mobile in with the fixed code and send its token on a call.
module DriverAppHelpers
  def driver_token(phone)
    integration_session.bearer_token = nil
    post code_api_v1_driver_app_session_path, params: { phone: }, as: :json
    post api_v1_driver_app_session_path, params: { phone:, code: "123456" }, as: :json
    json.dig(:data, :token)
  end

  def as(token) = { "Authorization" => "Bearer #{token}" }
end

RSpec.configure { it.include DriverAppHelpers, type: :request }
