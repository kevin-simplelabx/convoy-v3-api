# A client's request to cancel a booking, a day or one trip: recorded on their behalf (or sent from the Convoy App), then
# accepted or declined.
module Api
  module V1
    class BookingCancelRequestsController < BaseController
      before_action :set_booking

      # POST { booking_trip_id | booking_day_id (omit both for the whole booking), reason, requested_by_name }
      def create
        authorize BookingCancelRequest
        trip = params[:booking_trip_id].presence && @booking.trips.find(params[:booking_trip_id])
        day = !trip && params[:booking_day_id].presence && @booking.days.find(params[:booking_day_id])
        Bookings::CancelRequest.record(booking: @booking, trip:, day: day || nil, reason: params[:reason], actor: current_user,
                                       by_name: params[:requested_by_name].presence || @booking.coordinator_name)
        render_booking :created
      end

      # PATCH { decision: accept | decline, note }
      def update
        request = authorize @booking.cancel_requests.find(params[:id])
        Bookings::CancelRequest.call(request:, decision: params.require(:decision), user: current_user, note: params[:note])
        render_booking :ok
      end

      private

      def set_booking
        @booking = policy_scope(Booking).find(params[:booking_id])
      end

      def render_booking(status) = render_data(BookingsController.load(policy_scope(Booking), @booking.id), BookingBlueprint, view: :full, status:)
    end
  end
end
