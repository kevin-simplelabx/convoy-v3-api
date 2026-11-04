# The Convoy App sign-in of a Bearer token, or nil when the token is bad, expired, of another app, or signed out.
module ConvoyApp
  class FindToken < ApplicationService
    def initialize(token:)
      @token = token
    end

    def call
      return if @token.blank?

      payload = Warden::JWTAuth::TokenDecoder.new.call(@token)
      return unless payload["scp"] == "app_account"

      jwt = AppJwt.includes(:app_account).find_by(jti: payload["jti"], app_account_id: payload["sub"])
      return unless jwt&.exp&.future?

      jwt.touch_used!
      jwt
    rescue JWT::DecodeError
      nil
    end
  end
end
