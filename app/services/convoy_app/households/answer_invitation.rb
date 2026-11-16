# Accept / Not Me on a Family invite (Manual Invite): accepting puts the person in the Family; Not Me declines. One Family per
# account, so accepting while already in one is refused.
module ConvoyApp
  module Households
    class AnswerInvitation < ApplicationService
      def initialize(member:, accept:)
        @member = member
        @accept = accept
      end

      def call
        raise Error, "This invite was already answered" unless @member.invited?
        raise Error, "This Family no longer exists" if @member.household.discarded?

        @accept ? accept : @member.update!(status: :declined)
        @member
      end

      private

      def accept
        raise Error, "You are already in a Family" if @member.app_account.household_member

        @member.update!(status: :active, joined_at: Time.current)
      rescue ActiveRecord::RecordNotUnique
        raise Error, "You are already in a Family"
      end
    end
  end
end
