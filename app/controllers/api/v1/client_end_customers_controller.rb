# A client's end customers (nested under /clients/:client_id).
module Api
  module V1
    class ClientEndCustomersController < BaseController
      before_action :set_client

      def index
        authorize ClientEndCustomer
        render_list @client.end_customers.order(:name), ClientEndCustomerBlueprint
      end

      def create
        record = authorize @client.end_customers.new(record_params)
        record.save!
        render_data record, ClientEndCustomerBlueprint, status: :created
      end

      def update
        record = authorize @client.end_customers.find(params[:id])
        record.update!(record_params)
        render_data record, ClientEndCustomerBlueprint
      end

      def destroy
        authorize(@client.end_customers.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_client
        @client = Client.kept.find(params[:client_id])
      end

      def record_params = params.expect(client_end_customer: %i[name])
    end
  end
end
