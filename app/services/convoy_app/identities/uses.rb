# What each identity of an account is used for besides signing in (Mobile and Emails rows, and why one can't be removed):
# { identity_id => ["Tan Family", ...] }. The personal mobile is the Family's invite address; the personal email receives the
# Family's invoices and receipts when the person is its Billing Contact. A work email is used by the accepted employer
# ("Acme shuttle") and booking ("Bookings with Transport Co") links it found.
module ConvoyApp
  module Identities
    class Uses < ApplicationService
      def initialize(account:)
        @account = account
      end

      def call
        uses = @account.identities.to_h { [ it.id, [] ] }
        work_links(uses)
        member = @account.household_member
        return uses unless member

        personal = @account.identities.select(&:personal?)
        personal.find(&:mobile?)&.then { uses[it.id] << member.household.name }
        personal.find(&:email?)&.then { uses[it.id] << "Invoices and receipts" } if member.billing_contact?
        uses
      end

      private

      def work_links(uses)
        by_email = @account.identities.select(&:work?).index_by(&:value)
        OrganisationLinks.call(account: @account).select { it[:status] == "accepted" }.each do |link|
          identity = by_email[link[:matched_email]] or next
          uses[identity.id] << (link[:kind] == "shuttle" ? "#{link[:organisation]} shuttle" : "Bookings with #{link[:company]}")
        end
      end
    end
  end
end
