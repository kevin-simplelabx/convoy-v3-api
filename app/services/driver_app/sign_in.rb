# Sign in, step 2: the mobile and its one-time code. The first correct code creates the account (Create an Account);
# company records with that mobile become the person's memberships. Returns [token, driver_jwt].
module DriverApp
  class SignIn < ApplicationService
    def initialize(phone:, code:, device_name: nil)
      @phone = DriverAccount.normalize_value_for(:phone, phone)
      @code = code
      @device_name = device_name
    end

    def call
      record = DriverSignInCode.usable.where(phone: @phone).order(created_at: :desc).first
      raise Error, "That code has expired. Send a new one" unless record
      raise Error.new("That code is not right. Check the SMS and try again", details: { code: [ "is not right" ] }) unless record.check!(@code)

      account = DriverAccount.for_phone!(@phone)
      account.update!(phone_verified_at: account.phone_verified_at || Time.current)
      account.link_memberships!
      ShareProfile.call(account:)
      IssueToken.call(account:, name: @device_name)
    end
  end
end
