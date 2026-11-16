# Managed Clients › Staff Riders (nested under /clients/:client_id): people the Convoy App matched to the client's email
# domains, and removing one (ends their link in the app; declined / removed ones are listed too, as history).
module Api
  module V1
    class ClientRidersController < BaseController
      before_action :set_client

      # GET /clients/:client_id/riders → [{ id, name, matched_email, status, responded_at, created_at }]
      def index
        authorize ClientRider
        render_list @client.riders.includes(:app_account).order(created_at: :desc, id: :desc), ClientRiderBlueprint
      end

      def destroy
        rider = authorize @client.riders.find(params[:id])
        ClientRiders::Remove.call(rider:, actor: current_user)
        head :no_content
      end

      private

      def set_client
        @client = policy_scope(Client).kept.find(params[:client_id])
      end
    end
  end
end
