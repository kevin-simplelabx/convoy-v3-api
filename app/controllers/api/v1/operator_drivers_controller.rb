# Operator Drivers: invited like own drivers (DriverInviteActions); an active one can sit on one bus of their operator.
module Api
  module V1
    class OperatorDriversController < BaseController
      include DriverInviteActions

      # GET /operator_drivers/assign_preview?driver_id=&vehicle_id= — effects of the Change Driver / Assign Bus dialog.
      def assign_preview
        authorize OperatorDriver, :index?
        driver = params[:driver_id].presence && policy_scope(OperatorDriver).kept.find(params[:driver_id])
        vehicle = params[:vehicle_id].presence && Vehicle.kept.managed.find(params[:vehicle_id])
        render json: { data: OperatorDrivers::AssignPreview.call(driver:, vehicle:) }
      end

      # PATCH /operator_drivers/:id/assign_vehicle { vehicle_id } — swaps with the driver already on that bus.
      def assign_vehicle
        driver = authorize find_driver, :update?
        driver.assign_vehicle!(params[:vehicle_id].presence && Vehicle.kept.find(params[:vehicle_id]))
        render_data driver, OperatorDriverBlueprint
      end

      private

      def driver_class = OperatorDriver
      def driver_blueprint = OperatorDriverBlueprint
      def driver_includes = %i[operator vehicle last_vehicle display_set_by kyc_profile]
      def list_options(_drivers) = {}

      def driver_params = params.expect(operator_driver: %i[operator_id name phone photo remove_photo notes])
    end
  end
end
