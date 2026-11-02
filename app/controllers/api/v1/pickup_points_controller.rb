# Saved Pick-up Points (Import Route List window): Save Pick-up Point on a review stop, list, delete.
module Api
  module V1
    class PickupPointsController < BaseController
      def index
        authorize PickupPoint
        render json: { data: policy_scope(PickupPoint).order(:name).map { |p| view(p) } }
      end

      def create
        point = authorize PickupPoint.new(point_params)
        point.save!
        render json: { data: view(point) }, status: :created
      end

      def update
        point = authorize PickupPoint.find(params[:id])
        point.update!(point_params)
        render json: { data: view(point) }
      end

      def destroy
        authorize(PickupPoint.find(params[:id])).destroy!
        head :no_content
      end

      private

      def point_params = params.require(:pickup_point).permit(:name, :lat, :lng, :note, :postal_codes, postal_codes: [])
      def view(p) = p.slice(:id, :name, :postal_codes, :lat, :lng, :note)
    end
  end
end
