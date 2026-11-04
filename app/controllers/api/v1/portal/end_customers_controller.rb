# New Booking › Service For › Add New Customer (clients that are main contractors): their own customer, kept on the
# client for next time (the same name, any case, is not added twice).
module Api
  module V1
    module Portal
      class EndCustomersController < AppController
        # POST /portal/end_customers { name }
        def create
          authorize_portal Booking, :create?
          raise ApplicationService::Error, "Service For is for main contractors" unless current_client.main_contractor?

          name = params.require(:name).to_s.squish
          raise ApplicationService::Error, "Enter the customer's name" if name.blank?

          customer = current_client.end_customers.where("lower(name) = ?", name.downcase).first ||
                     current_client.end_customers.create!(company_id: current_client.company_id, name:)
          render json: { data: { id: customer.id, name: customer.name } }, status: :created
        end
      end
    end
  end
end
