# Base for Convoy App › Bookings. An account key (`account`) is one of the person's booking accounts (GET
# /app/bookings/accounts); a booking id is found only among the person's own bookings of their accounts (else 404). Every
# read and write runs inside that account's company and time zone.
module Api
  module V1
    module ConvoyApp
      class BookingBaseController < BaseController
        private

        def account = @account ||= ::ConvoyApp::Bookings.account!(current_account, params.require(:account))

        # Yields [account, booking] inside the booking's company.
        def with_booking(id = params[:id], &)
          account, booking = ::ConvoyApp::Bookings.find!(current_account, id)
          ::ConvoyApp::Bookings.within(account) { yield account, ::Booking.includes(*::ConvoyApp::Bookings::Present::INCLUDES).find(booking.id) }
        end

        def within(acc = account, &) = ::ConvoyApp::Bookings.within(acc, &)

        def detail(acc, booking)
          booking = ::Booking.includes(*::ConvoyApp::Bookings::Present::INCLUDES).find(booking.id)
          runs = ::ConvoyApp::Bookings::Runs.load([ booking ])
          ::ConvoyApp::Bookings::Present.new(acc, booking, runs).detail
        end

        # The booking New Booking sends (as the Client Portal: days and trips in the Bookings::Save shape; no client, no standby).
        def booking_params
          raw = params.require(:booking)
          raw.permit(:title, :notes, :po_number, :client_site_id, :client_bill_fund_id,
                     days: [ :date, { trips: ::Bookings::TripBuilder::PERMIT - [ { standby: ::Bookings::TripBuilder::STANDBY_FIELDS },
                                                                                 { return_standby: ::Bookings::TripBuilder::STANDBY_FIELDS } ] } ])
        end
      end
    end
  end
end
