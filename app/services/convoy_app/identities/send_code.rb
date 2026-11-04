# Mobile and Emails, step 1: check the mobile / email (Identities::Check) and send its code.
# Returns { kind, value, display, tag, replace }.
module ConvoyApp
  module Identities
    class SendCode < ApplicationService
      def initialize(account:, ip: nil, **input)
        @account = account
        @input = input
        @ip = ip
      end

      def call
        ok = Check.call(account: @account, **@input)
        AppSignInCode.issue!(ok[:target].value, purpose: :verify, account: @account, ip: @ip)
        { **ok[:target].to_h, tag: ok[:tag], replace: ok[:replace] }
      end
    end
  end
end
