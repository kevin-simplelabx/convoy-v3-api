# Asked to Join (Admin only): approve with the relationship, or decline.
module ConvoyApp
  module Households
    class ReviewRequest < ApplicationService
      def initialize(member:, approve:, relationship: nil)
        @member = member
        @approve = approve
        @relationship = relationship
      end

      def call
        raise Error, "This request was already answered" unless @member.requested?

        @approve ? approve : @member.update!(status: :declined)
        @member
      end

      private

      def approve
        unless HouseholdMember::RELATIONSHIPS.include?(@relationship)
          raise Error.new("Choose how #{@member.first_name} is related", details: { relationship: [ "can't be blank" ] })
        end

        @member.update!(status: :active, relationship: @relationship, joined_at: Time.current)
      rescue ActiveRecord::RecordNotUnique
        raise Error, "#{@member.first_name} joined another Family in the meantime"
      end
    end
  end
end
