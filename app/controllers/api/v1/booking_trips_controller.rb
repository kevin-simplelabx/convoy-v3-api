# One trip of a booking: Approve & Convert to Trip (or Approve Without Waiting), Reject, and the client's steps
# recorded on their behalf (Client Acknowledged, client approval done / declined). Each returns the whole booking.
module Api
  module V1
    class BookingTripsController < BaseController
      before_action :set_trip

      # POST { trip_value, return_trip_value (Two Way), how (Phone | Email | WhatsApp | In person: approving without waiting), note }
      def approve
        authorize @trip
        Bookings::Approve.call(trip: @trip, user: current_user, trip_value: params[:trip_value], return_trip_value: params[:return_trip_value],
                               how: params[:how], note: params[:note])
        render_booking
      end

      # PATCH { reason }
      def reject = act(:reject)
      # PATCH { how, by_name } — the client accepted our changes (Client Acknowledged, standing in for the Client Portal).
      def acknowledge = act(:acknowledge)

      private

      def set_trip
        @trip = BookingTrip.joins(:booking).merge(policy_scope(Booking))
                           .includes(:day, :points, :standbys, booking: :client, vehicles: :vehicle_type).find(params[:id])
      end

      def act(action)
        authorize @trip, :"#{action}?"
        Bookings::TripAction.call(trip: @trip, action:, actor: current_user, reason: params[:reason], how: params[:how], by_name: params[:by_name])
        render_booking
      end

      def render_booking = render_data(BookingsController.load(policy_scope(Booking), @trip.booking_id), BookingBlueprint, view: :full)
    end
  end
end
