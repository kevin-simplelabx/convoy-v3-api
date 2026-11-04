# Files on a booking (passenger list, itinerary), up to 10.
module Api
  module V1
    class BookingAttachmentsController < BaseController
      before_action :set_booking

      def create
        attachment = authorize @booking.attachments.new(file: params.require(:file)).stamp_actor(:uploaded, current_user)
        attachment.save!
        render json: { data: { id: attachment.id }.merge(attachment.decorate.file_info(:file)) }, status: :created
      end

      def destroy
        authorize(@booking.attachments.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_booking
        @booking = policy_scope(Booking).find(params[:booking_id])
      end
    end
  end
end
