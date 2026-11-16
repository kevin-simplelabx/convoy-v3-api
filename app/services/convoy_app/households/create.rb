# Set Up Your Family step 1: the family, its address and who the Billing Contact is. The person who sets it up is the Admin
# (and the Billing Contact unless they switch it off); everyone else joins by invite. One Family per account.
module ConvoyApp
  module Households
    class Create < ApplicationService
      BOOL = ActiveModel::Type::Boolean.new
      FIELDS = %i[name postal block street floor unit line2 billing_address].freeze

      def initialize(account:, params:)
        @account = account
        @params = params.to_h.symbolize_keys
      end

      def call
        attrs = @params.slice(*FIELDS)
        attrs[:billing_same] = @params.key?(:billing_same) ? BOOL.cast(@params[:billing_same]) : true
        household = Household.new(attrs.merge(created_by: @account))
        check!(household)
        locate(household)
        Household.transaction do
          @account.with_lock do
            raise Error, "You are already in a Family" if @account.household_member

            household.save!
            household.members.create!(app_account: @account, status: :active, admin: true, invited_via: :creator, joined_at: Time.current,
                                      billing_contact: @params.key?(:billing_contact) ? BOOL.cast(@params[:billing_contact]) : true,
                                      relationship: @params[:relationship].presence, invite_phone: @account.mobile&.value)
          end
        end
        household
      rescue ActiveRecord::RecordNotUnique
        raise Error, "You are already in a Family"
      end

      private

      # The messages of the screen, in its order.
      def check!(household)
        field, message = if household.name.blank? then [ :name, "Enter the family name" ]
        elsif !household.postal.to_s.match?(/\A\d{6}\z/) then [ :postal, "Enter a 6-digit postal code" ]
        elsif household.block.blank? || household.street.blank? then [ :block, "Enter the block or house number and the street" ]
        elsif !household.billing_same? && household.billing_address.blank? then [ :billing_address, "Enter the billing address" ]
        end
        raise Error.new(message, details: { field => [ message ] }) if field
        raise Error.new("Choose how you are related to the children", details: { relationship: [ "is not valid" ] }) if bad_relationship?
      end

      def bad_relationship? = @params[:relationship].present? && HouseholdMember::RELATIONSHIPS.exclude?(@params[:relationship])

      # Kept for fares later (distance from the home); a postal OneMap cannot answer is saved without a point.
      def locate(household)
        hit = Geo::OneMap.lookup(household.postal)
        household.assign_attributes(lat: hit[:lat], lng: hit[:lng]) if hit
      rescue Geo::OneMap::Unavailable
        nil
      end
    end
  end
end
