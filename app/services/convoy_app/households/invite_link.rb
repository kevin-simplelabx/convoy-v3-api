# Quick Invite: the Family's link (works 7 days). The live one is reused so the message the adult already sent keeps working.
module ConvoyApp
  module Households
    class InviteLink < ApplicationService
      def initialize(household:, account:)
        @household = household
        @account = account
      end

      def call
        @household.with_lock do
          @household.invite_links.live.order(:expires_at).last || @household.invite_links.create!(created_by: @account)
        end
      end
    end
  end
end
