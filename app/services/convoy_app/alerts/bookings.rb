# Booking alerts for the person who booked in the app or the Portal (the client user's linked account, the Individual
# client's account, the account that booked Pay Myself), except the one who did it:
#   confirmed       the company confirmed a trip (Bookings::Approve)
#   changed         the company changed trips (Bookings::Save): Accept Changes or Can't Accept in the app
#   declined        the company declined a trip (Bookings::TripAction reject)
#   cancelled       the company accepted a cancellation request (Bookings::CancelRequest)
#   cancel_declined the company declined it
# Tap opens the booking. Inside the booking's company.
module ConvoyApp
  module Alerts
    class Bookings < ApplicationService
      def initialize(booking:, kind:, trip: nil, request: nil, at: Time.current)
        @booking = booking
        @kind = kind.to_s
        @trip = trip
        @request = request
        @at = at
      end

      def call
        ids = Alerts.without_actor(accounts)
        return 0 if ids.empty?

        title, body, key = text
        Alerts.write(Alerts.rows_for(ids, kind: "booking_#{@kind}", title:, body:, company_id: @booking.company_id, target: "booking",
                                          target_id: @booking.id, dedupe_key: "booking:#{@kind}:#{key}"))
      end

      # The app accounts of the booking: Pay Myself / app booker, the Individual client's person, the linked client user while
      # the link can still open the booking (Bookings.link_live?: a paused or removed link is not told).
      def accounts
        [ @booking.created_by_app_account_id, @booking.client&.app_account_id, linked_account_id ].compact.uniq
      end

      private

      def linked_account_id
        user = @booking.created_by_client_user
        return unless user&.app_account && @booking.client&.kept? && Company.active.exists?(id: @booking.company_id)

        user.app_account_id if ConvoyApp::Bookings.link_live?(user, user.app_account, @at.to_date)
      end

      def tc = @booking.company.decorate.display_name
      def name = [ @booking.number, @booking.title ].compact_blank.join(" ")
      def day(trip) = trip.date.strftime("%a %-d %b")

      def text
        case @kind
        when "confirmed" then [ "#{@booking.number} confirmed by #{tc}", "The trip on #{day(@trip)} is confirmed. Bus and driver details show in the booking from the day before.", @trip.id ]
        when "changed" then [ "Changes to #{name}", "#{tc} changed the booking. Accept the changes or tell them why you can't.", "#{@booking.id}:#{@at.to_i}" ]
        when "declined" then [ "#{@booking.number} declined", "#{tc} declined the trip on #{day(@trip)}#{": #{@trip.rejection_reason}" if @trip.rejection_reason.present?}.", @trip.id ]
        when "cancelled" then [ "Cancellation accepted · #{@booking.number}", "#{tc} cancelled #{what}#{" (charge #{Parents::Present.money(@request.fee_quoted)})" if @request.fee_quoted.positive?}.", @request.id ]
        else [ "Cancellation not accepted · #{@booking.number}", "#{tc} kept #{what}#{": #{@request.resolution_note}" if @request.resolution_note}.", @request.id ]
        end
      end

      def what
        case @request.scope
        when "trip" then "the trip on #{day(@request.booking_trip)}"
        when "day" then @request.booking_day.date.strftime("%a %-d %b")
        else "the booking"
        end
      end
    end
  end
end
