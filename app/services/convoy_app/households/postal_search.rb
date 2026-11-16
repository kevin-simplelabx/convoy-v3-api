# Set Up Your Family › postal code search: fills Block and Street from OneMap. Not found (or OneMap down) is an answer, not an
# error: the person types the block and street.
module ConvoyApp
  module Households
    class PostalSearch < ApplicationService
      def initialize(postal:)
        @postal = postal.to_s.gsub(/\D/, "")
      end

      def call
        raise Error.new("Enter a 6-digit postal code", details: { postal: [ "must be 6 digits" ] }) unless @postal.match?(/\A\d{6}\z/)

        hit = Geo::OneMap.lookup(@postal)
        return { postal: @postal, found: false, message: "Postal code not found, type the block and street" } unless hit

        # OneMap answers "412 BEDOK NORTH AVENUE 2": the house number is the first word.
        block, street = hit[:address].to_s.split(" ", 2)
        { postal: @postal, found: true, block:, street: street.to_s.squish.titleize, address: hit[:address], lat: hit[:lat], lng: hit[:lng] }
      rescue Geo::OneMap::Unavailable
        { postal: @postal, found: false, message: "Postal code not found, type the block and street" }
      end
    end
  end
end
