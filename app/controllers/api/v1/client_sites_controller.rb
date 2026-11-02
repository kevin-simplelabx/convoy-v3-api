# A client's sites (nested under /clients/:client_id): Add Site, Edit Site (school, own billing, Send Invoices To),
# Remove (refused while trips use the site).
module Api
  module V1
    class ClientSitesController < BaseController
      before_action :set_client

      def index
        authorize ClientSite
        render_list @client.sites.includes(:school, :billing_contacts).order(:name), ClientSiteBlueprint
      end

      def create
        site = authorize @client.sites.new
        render_data ClientSites::Save.call(site:, params: record_params, user: current_user), ClientSiteBlueprint, status: :created
      end

      def update
        site = authorize @client.sites.find(params[:id])
        render_data ClientSites::Save.call(site:, params: record_params), ClientSiteBlueprint
      end

      def destroy
        authorize(@client.sites.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_client
        @client = Client.kept.find(params[:client_id])
      end

      def record_params
        params.expect(client_site: [ :name, :address, :lat, :lng, :school_id, :own_billing, :billing_name, :billing_uen, :billing_address,
                                     { billing_contacts: [ %i[name email send_as attention] ] } ])
      end
    end
  end
end
