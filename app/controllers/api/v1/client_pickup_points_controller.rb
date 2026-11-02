# A client's pickup points (nested under /clients/:client_id).
module Api
  module V1
    class ClientPickupPointsController < BaseController
      before_action :set_client

      def index
        authorize ClientPickupPoint
        render_list @client.pickup_points.includes(:created_by).order(:name), ClientPickupPointBlueprint
      end

      def create
        record = authorize @client.pickup_points.new(record_params.merge(created_by: current_user))
        record.save!
        render_data record, ClientPickupPointBlueprint, status: :created
      end

      def update
        record = authorize @client.pickup_points.find(params[:id])
        record.update!(record_params)
        render_data record, ClientPickupPointBlueprint
      end

      def destroy
        authorize(@client.pickup_points.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_client
        @client = Client.kept.find(params[:client_id])
      end

      def record_params = params.expect(client_pickup_point: %i[name address postal_code lat lng note])
    end
  end
end
