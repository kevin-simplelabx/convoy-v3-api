# A client's sites (nested under /clients/:client_id).
module Api
  module V1
    class ClientSitesController < BaseController
      before_action :set_client

      def index
        authorize ClientSite
        render_list @client.sites.order(:name), ClientSiteBlueprint
      end

      def create
        record = authorize @client.sites.new(record_params)
        record.save!
        render_data record, ClientSiteBlueprint, status: :created
      end

      def update
        record = authorize @client.sites.find(params[:id])
        record.update!(record_params)
        render_data record, ClientSiteBlueprint
      end

      def destroy
        authorize(@client.sites.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_client
        @client = Client.kept.find(params[:client_id])
      end

      def record_params = params.expect(client_site: %i[name address lat lng])
    end
  end
end
