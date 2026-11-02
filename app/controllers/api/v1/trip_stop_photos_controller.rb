# Stop photos from the trip drawer (up to 3 per stop, resized to 1280 px); the same photos the trip form shows.
module Api
  module V1
    class TripStopPhotosController < BaseController
      before_action :set_stop

      def create
        photo = authorize @stop.photos.new(photo: params.require(:photo), position: @stop.photos.size)
        raise ApplicationService::Error, "Up to #{TripStop::MAX_PHOTOS} photos per stop" if @stop.photos.size > TripStop::MAX_PHOTOS

        photo.save!
        render json: { data: { id: photo.id }.merge(photo.decorate.file_info(:photo, versions: [ :thumb ])) }, status: :created
      end

      def destroy
        authorize(@stop.photos.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_stop
        @stop = Trip.kept.find(params[:trip_id]).stops.find(params[:stop_id])
      end
    end
  end
end
