# A new Convoy Driver app sign-in: JWT (scope driver_account) and its allowlist row. One phone at a time, so the
# account's other sign-ins end. A driver working for one company gets it picked straight away. Returns [token, driver_jwt].
module DriverApp
  class IssueToken < ApplicationService
    def initialize(account:, name: nil)
      @account = account
      @name = name
    end

    def call
      DriverJwt.transaction do
        @account.jwts.find_each { |old| SignOut.call(jwt: old) }
        token, payload = Warden::JWTAuth::UserEncoder.new.call(@account, :driver_account, nil)
        jwt = @account.jwts.create!(jti: payload["jti"], aud: payload["aud"], exp: Time.zone.at(payload["exp"]),
                                    name: @name.to_s.strip.truncate(100).presence, last_used_at: Time.current)
        active = @account.memberships.select(&:active?)
        PickMembership.call(jwt:, member: active.first) if active.one?
        @account.update_column(:last_sign_in_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
        [ token, jwt ]
      end
    end
  end
end
