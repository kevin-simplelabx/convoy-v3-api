# Add a Photo of an adult: the bus attendant checks the adult's face against it before hand-over; no photo, no hand-over.
module ConvoyApp
  module Households
    class SaveMemberPhoto < ApplicationService
      def initialize(member:, photo:)
        @member = member
        @photo = photo
      end

      def call
        raise Error.new("Add a photo first", details: { photo: [ "can't be blank" ] }) if @photo.blank?
        raise Error, "#{@member.first_name} has not accepted the invite yet" unless @member.active?

        @member.update!(photo: @photo)
        @member
      end
    end
  end
end
