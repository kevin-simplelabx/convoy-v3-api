# Sign in, step 1: a one-time code for a mobile number (recorded; not sent until SMS is set up). At most 5 codes an
# hour per mobile. Returns { phone, phone_display, new_account } — a new account is created by the first correct code.
module DriverApp
  class SendCode < ApplicationService
    PER_HOUR = 5

    def initialize(phone:, ip: nil)
      @phone = DriverAccount.normalize_value_for(:phone, phone)
      @ip = ip
    end

    def call
      parsed = Phonelib.parse(@phone)
      raise Error.new("Enter a valid mobile number", details: { phone: [ "is not a valid mobile number" ] }) unless parsed.valid?
      raise Error, "Too many codes asked for. Try again in an hour" if DriverSignInCode.where(phone: @phone, created_at: 1.hour.ago..).count >= PER_HOUR

      DriverSignInCode.issue!(@phone, ip: @ip)
      { phone: @phone, phone_display: parsed.international, new_account: !DriverAccount.exists?(phone: @phone) }
    end
  end
end
