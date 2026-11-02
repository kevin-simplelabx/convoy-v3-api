# Emails a one-time code (first sign-in or forgotten password). At most 5 codes an hour per person.
# Returns the plain code (shown on dev / staging only, see Portal::SessionsController#dev_code).
module Portal
  class SendCode < ApplicationService
    PER_HOUR = 5

    def initialize(account:, purpose:, ip: nil)
      @account = account
      @purpose = purpose
      @ip = ip
    end

    def call
      if @account.sign_in_codes.where(created_at: 1.hour.ago..).count >= PER_HOUR
        raise Error, "Too many codes asked for. Try again in an hour"
      end

      _record, code = PortalSignInCode.issue!(@account, purpose: @purpose, ip: @ip)
      PortalMailer.sign_in_code(@account, code, @purpose.to_s).deliver_later
      code
    end
  end
end
