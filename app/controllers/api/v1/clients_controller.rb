# Managed Clients (list for the trip form's Client picker, Add New Client).
module Api
  module V1
    class ClientsController < BaseController
      def index
        authorize Client
        scope = policy_scope(Client).kept.ransack(ransack_params).result.order(:name)
        render_page scope, ClientBlueprint
      end

      def show
        client = authorize policy_scope(Client).kept.includes(:sites, :end_customers, :pickup_points).find(params[:id])
        render_data client, ClientBlueprint, view: :full
      end

      def create
        client = authorize Client.new(client_params)
        client.save!
        render_data client, ClientBlueprint, view: :full, status: :created
      end

      def update
        client = authorize Client.kept.find(params[:id])
        client.update!(client_params)
        render_data client, ClientBlueprint, view: :full
      end

      def destroy
        authorize(Client.kept.find(params[:id])).discard!
        head :no_content
      end

      private

      def client_params
        params.expect(client: %i[kind name uen contact_name phone email billing_address on_time_allowance])
      end
    end
  end
end
