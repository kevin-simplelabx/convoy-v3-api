# Mobile and Emails › remove (X): not the last one (it signs in) and not one in use (Family, invoices, an employer or
# school link): add another first, then switch.
module ConvoyApp
  module Identities
    class Remove < ApplicationService
      def initialize(identity:)
        @identity = identity
      end

      def call
        account = @identity.app_account
        AppAccount.transaction do
          account.lock!
          raise Error, "Used to sign in. Add another first, then switch" if account.identities.reload.size <= 1

          uses = Uses.call(account:)[@identity.id]
          raise Error, "Used by #{uses.to_sentence}. Add another first, then switch" if uses.present?

          @identity.destroy!
        end
      end
    end
  end
end
