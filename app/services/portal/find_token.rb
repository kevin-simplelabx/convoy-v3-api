# The Client Portal sign-in of a Bearer token, or nil when the token is bad, expired, for Convoy OS, or signed out.
module Portal
  class FindToken < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      return if @token.blank?

      payload = Warden::JWTAuth::TokenDecoder.new.call(@token)
      return unless payload["scp"] == "portal_account"

      jwt = PortalJwt.includes(:portal_account).find_by(jti: payload["jti"], portal_account_id: payload["sub"])
      return unless jwt&.exp&.future?

      jwt.touch_used!
      jwt
    rescue JWT::DecodeError
      nil
    end
  end
end
