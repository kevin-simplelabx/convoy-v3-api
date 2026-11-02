# Attachments of a trip.
module Api
  module V1
    class TripAttachmentsController < BaseController
      before_action :set_trip

      def create
        attachment = authorize @trip.attachments.new(file: params.require(:file), uploaded_by: current_user)
        attachment.save!
        render json: { data: { id: attachment.id }.merge(attachment.decorate.file_info(:file)) }, status: :created
      end

      def destroy
        authorize(@trip.attachments.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_trip
        @trip = Trip.kept.find(params[:trip_id])
      end
    end
  end
end
