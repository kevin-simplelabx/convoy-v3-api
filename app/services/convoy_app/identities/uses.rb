# What each identity of an account is used for besides signing in (Mobile and Emails rows, and why one can't be removed):
# { identity_id => ["Tan Family", ...] }. Later phases add the Family, invoices and employer / school links.
module ConvoyApp
  module Identities
    class Uses < ApplicationService
      def initialize(account:)
        @account = account
      end

      def call
        @account.identities.to_h { [ it.id, [] ] }
      end
    end
  end
end
