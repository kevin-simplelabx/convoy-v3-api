# Convoy App › CCA Bus, Not Riding / Riding After All on a booked ride: tells the bus not to wait and frees the seat (the ride
# is still charged); a ride already gone cannot be changed, nor one on a day the bus does not run. Riding After All needs a
# seat again. Any adult of the Family.
module ConvoyApp
  module Cca
    class NotRiding < ApplicationService
      def initialize(member:, booking_id:, not_riding:)
        @household = member.household
        @id = booking_id
        @flag = ActiveModel::Type::Boolean.new.cast(not_riding) ? true : false
      end

      def call
        Parents.companies(@household).each do |company|
          found = Parents.within(company) do
            booking = CcaBooking.where(family_id: Family.where(household_id: @household.id).select(:id)).includes(:school).find_by(id: @id)
            booking && [ change(booking) ]
          end
          return found.first if found
        end
        raise ActiveRecord::RecordNotFound
      end

      private

      def change(booking)
        school = booking.school
        ApplicationRecord.transaction do
          school.lock!
          booking.reload
          raise Error, "A ride that has gone cannot be changed" if booking.date < Date.current
          raise Error, "The CCA bus is not running on #{CcaRides.label(booking.date)}" if school.cca_off_days.exists?(date: booking.date)

          if !@flag && booking.not_riding && CcaRides.taken(school, booking.date) >= CcaRides.setting(school).seats
            raise Error, "The CCA bus on #{CcaRides.label(booking.date)} is full, so the seat cannot be taken back"
          end
          booking.update!(not_riding: @flag)
        end
        booking
      end
    end
  end
end
