# Account › Email: an email and password so the driver can sign in without the SMS code ("protects your account if
# your number is recycled"). Changing them again needs the current password.
module DriverApp
  class SetEmail < ApplicationService
    def initialize(account:, email:, password:, password_confirmation: nil, current_password: nil)
      @account = account
      @email = email
      @password = password
      @password_confirmation = password_confirmation
      @current_password = current_password
    end

    def call
      if @account.password_set? && !@account.valid_password?(@current_password.to_s)
        raise Error.new("Your current password is not right", details: { current_password: [ "is not right" ] })
      end
      raise Error.new("Enter your email", details: { email: [ "can't be blank" ] }) if @email.blank?
      raise Error.new("Enter a password", details: { password: [ "can't be blank" ] }) if @password.blank?

      @account.assign_attributes(email: @email, password: @password, password_confirmation: @password_confirmation || @password,
                                 password_set_at: Time.current)
      @account.transaction do
        @account.save!
        ShareProfile.call(account: @account)
      end
      @account
    end
  end
end
