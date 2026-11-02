# Log cards of a vehicle (Edit Vehicle): current and past, upload (or attach a read), pick the plate, delete a past card.
module Api
  module V1
    class VehicleLogCardsController < BaseController
      before_action :set_vehicle

      def index
        authorize VehicleLogCard
        render_list @vehicle.log_cards.includes(:uploaded_by), VehicleLogCardBlueprint
      end

      # POST { file } or { document_read_id }
      def create
        authorize VehicleLogCard
        result = VehicleDocuments::AttachLogCard.call(vehicle: @vehicle, user: current_user, file: params[:file],
                                                      document_read: document_read)
        render json: { data: VehicleLogCardBlueprint.render_as_hash(result.card.decorate), meta: { filled: result.filled } },
               status: :created
      end

      # PATCH :id/resolve_plate { use: card | vehicle }
      def resolve_plate
        card = authorize @vehicle.log_cards.find(params[:id])
        render_data VehicleDocuments::ResolvePlate.call(card:, use: params.require(:use)), VehicleLogCardBlueprint
      end

      def destroy
        authorize(@vehicle.log_cards.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_vehicle
        @vehicle = Vehicle.kept.find(params[:vehicle_id])
      end

      def document_read
        params[:document_read_id].presence && policy_scope(DocumentRead).find(params[:document_read_id])
      end
    end
  end
end
