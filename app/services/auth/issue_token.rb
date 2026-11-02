# Sign-in: a new JWT for the user plus its allowlist row (device name). Returns [token, allowlisted_jwt].
module Auth
  class IssueToken < ApplicationService
    def initialize(user:, name: nil)
      @user = user
      @name = name
    end

    def call
      token, payload = Warden::JWTAuth::UserEncoder.new.call(@user, :user, nil)
      jwt = @user.allowlisted_jwts.create!(jti: payload["jti"], aud: payload["aud"], exp: Time.zone.at(payload["exp"]),
                                           name: @name.to_s.strip.truncate(100).presence, last_used_at: Time.current)
      [ token, jwt ]
    end
  end
end
