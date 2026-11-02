# Client Portal sign-in: a new JWT (scope portal_account) and its allowlist row. A person with one client account
# gets it picked straight away. Returns [token, portal_jwt].
module Portal
  class IssueToken < ApplicationService
    def initialize(account:, name: nil)
      @account = account
      @name = name
    end

    def call
      token, payload = Warden::JWTAuth::UserEncoder.new.call(@account, :portal_account, nil)
      accounts = @account.accounts
      jwt = @account.portal_jwts.create!(jti: payload["jti"], aud: payload["aud"], exp: Time.zone.at(payload["exp"]),
                                         name: @name.to_s.strip.truncate(100).presence, last_used_at: Time.current,
                                         client_user: accounts.one? ? accounts.first : nil)
      @account.update_column(:last_sign_in_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
      [ token, jwt ]
    end
  end
end
