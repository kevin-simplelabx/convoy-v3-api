# Sign in, step 2: the mobile or email and its code. A value no account has yet creates the account with it (a mobile and
# a personal-provider email are personal; any other email is a work email); the person then fills Create Your Account.
# Signing in again within 30 days of Delete Account keeps the account. Returns [token, app_jwt].
module ConvoyApp
  class SignIn < ApplicationService
    def initialize(code:, mobile: nil, email: nil, device_name: nil)
      @target = Target.call(mobile:, email:)
      @code = code
      @device_name = device_name
    end

    def call
      AppSignInCode.check!(@target.value, @code, purpose: :sign_in)
      account = AppIdentity.find_by(kind: @target.kind, value: @target.value)&.app_account || create_account
      account.update!(delete_requested_at: nil) if account.delete_requested_at
      IssueToken.call(account:, name: @device_name)
    end

    private

    # Two phones signing up with the same value at once: the second finds the first one's account.
    def create_account
      tag = @target.kind == "email" && !ConvoyApp.free_mail?(@target.domain) ? "work" : "personal"
      AppAccount.transaction do
        account = AppAccount.create!
        account.identities.create!(kind: @target.kind, tag:, value: @target.value, verified_at: Time.current)
        account
      end
    rescue ActiveRecord::RecordNotUnique
      AppIdentity.find_by!(kind: @target.kind, value: @target.value).app_account
    end
  end
end
