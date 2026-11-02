# The allowlist row of a Bearer token, or nil when the token is bad, expired, for another scope or signed out.
module Auth
  class FindToken < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      return if @token.blank?

      payload = Warden::JWTAuth::TokenDecoder.new.call(@token)
      return unless payload["scp"] == "user"

      jwt = AllowlistedJwt.includes(:user).find_by(jti: payload["jti"], user_id: payload["sub"])
      return unless jwt&.exp&.future?

      jwt.touch_used!
      jwt
    rescue JWT::DecodeError
      nil
    end
  end
end
