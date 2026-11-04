# A new Convoy App sign-in: JWT (scope app_account) and its allowlist row. Other phones stay signed in.
# Returns [token, app_jwt].
module ConvoyApp
  class IssueToken < ApplicationService
    def initialize(account:, name: nil)
      @account = account
      @name = name
    end

    def call
      token, payload = Warden::JWTAuth::UserEncoder.new.call(@account, :app_account, nil)
      jwt = @account.jwts.create!(jti: payload["jti"], aud: payload["aud"], exp: Time.zone.at(payload["exp"]),
                                  name: @name.to_s.strip.truncate(100).presence, last_used_at: Time.current)
      @account.update_column(:last_sign_in_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
      [ token, jwt ]
    end
  end
end
