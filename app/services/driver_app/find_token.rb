# The Convoy Driver app sign-in of a Bearer token, or nil when the token is bad, expired, of another app, or signed out.
module DriverApp
  class FindToken < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      return if @token.blank?

      payload = Warden::JWTAuth::TokenDecoder.new.call(@token)
      return unless payload["scp"] == "driver_account"

      jwt = DriverJwt.includes(:driver_account).find_by(jti: payload["jti"], driver_account_id: payload["sub"])
      return unless jwt&.exp&.future?

      jwt.touch_used!
      jwt
    rescue JWT::DecodeError
      nil
    end
  end
end
