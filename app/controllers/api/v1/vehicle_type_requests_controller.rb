# Vehicle Types > Request a New Type (company) and Requests From Companies (Convoy Admin: Add Type / Decline).
module Api
  module V1
    class VehicleTypeRequestsController < BaseController
      def index
        authorize VehicleTypeRequest
        scope = policy_scope(VehicleTypeRequest).includes(:company, :requested_by).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        render_page scope, VehicleTypeRequestBlueprint
      end

      def create
        request = authorize VehicleTypeRequest.new(request_params.merge(company: current_company, requested_by: current_user))
        request.save!
        render_data request, VehicleTypeRequestBlueprint, status: :created
      end

      # Add Type: { tyre_layout } optional (by seats otherwise). An existing type with the same name and seats is used.
      def approve
        request = authorize pending_request
        request.approve!(user: current_user, tyre_layout: params[:tyre_layout])
        render_data request, VehicleTypeRequestBlueprint
      end

      def decline
        request = authorize pending_request
        request.decline!(user: current_user)
        render_data request, VehicleTypeRequestBlueprint
      end

      private

      def pending_request = policy_scope(VehicleTypeRequest).pending.find(params[:id])

      def request_params = params.expect(vehicle_type_request: %i[name seats reason])
    end
  end
end
