module Api
  module V1
    class VehiclesController < BaseController
      before_action :require_company!
      before_action -> { require_permission!("vehicles") }, only: [ :create, :destroy ]

      # GET /api/v1/vehicles
      def index
        vehicles = current_company.vehicles.order(:plate)
        render json: VehicleBlueprint.render_as_hash(vehicles)
      end

      # POST /api/v1/vehicles
      def create
        p = vehicle_params
        if p[:id].present?
          vehicle = current_company.vehicles.find_by(id: p[:id])
          if vehicle
            vehicle.update!(p.except(:id))
          else
            vehicle = current_company.vehicles.create!(p.except(:id))
          end
        else
          vehicle = current_company.vehicles.create!(p)
        end
        render json: VehicleBlueprint.render_as_hash(vehicle)
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.record.errors.full_messages.first)
      end

      # DELETE /api/v1/vehicles/:id
      def destroy
        vehicle = current_company.vehicles.find_by(id: params[:id])
        return render_error("Vehicle not found", :not_found) unless vehicle
        vehicle.destroy!
        render json: { ok: true }
      end

      private

      def vehicle_params
        params.permit(
          :id, :plate, :vehicle_type, :seats,
          :driver_name, :driver_contact, :notes,
          :operator_id, :operator_name, :operator_contact, :operator_phone,
          :tags, :photo, :driver_photo, :sample
        )
      end
    end
  end
end
