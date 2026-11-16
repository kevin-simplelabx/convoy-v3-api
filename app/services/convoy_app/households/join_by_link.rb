# Opening a Quick Invite link: shows whose Family it is (find), and asks to join (call). Nobody joins without approval: the
# person shows up under Asked to Join and the Admin sets the relationship and approves.
module ConvoyApp
  module Households
    class JoinByLink < ApplicationService
      def initialize(token:, account: nil)
        @token = token.to_s.strip.upcase
        @account = account
      end

      # The live link and its Family; 404 when no such link, 422 "link_expired" when it ran out or the Family is gone.
      def find
        link = HouseholdInviteLink.includes(:household).find_by!(token: @token)
        raise Error.new("This invite link has expired. Ask for a new one", code: "link_expired") unless link.live? && link.household.kept?

        link
      end

      def call
        household = find.household
        raise Error, "You are already in a Family" if @account.household_member

        household.with_lock do
          member = household.members.find_or_initialize_by(app_account: @account)
          return member if member.requested? || member.active?

          member.assign_attributes(status: :requested, invited_via: :quick, invite_phone: @account.mobile&.value, relationship: nil)
          member.save!
          member
        end
      end
    end
  end
end
