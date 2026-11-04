# Sign in, step 1: a one-time code for a mobile or email (recorded; not sent until SMS / email go out). The same step
# signs up: the first correct code creates the account. Returns { kind, value, display }.
module ConvoyApp
  class SendCode < ApplicationService
    def initialize(mobile: nil, email: nil, ip: nil)
      @target = Target.call(mobile:, email:)
      @ip = ip
    end

    def call
      AppSignInCode.issue!(@target.value, purpose: :sign_in, ip: @ip)
      @target.to_h
    end
  end
end
