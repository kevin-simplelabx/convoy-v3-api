# Platform vehicle types. Companies see every type with enabled true/false and turn types on or off;
# Convoy Admin adds, edits (tyre layout) and removes custom types. The Vehicle Types page also shows how many own and
# operator buses have each type's seats.
module Api
  module V1
    class VehicleTypesController < BaseController
      def index
        authorize VehicleType
        render_list VehicleType.all, VehicleTypeBlueprint, disabled_ids:, fleet: fleet_counts,
                                                           meta: { tyre_layouts: VehicleType::TYRE_LAYOUTS }
      end

      def create
        type = authorize VehicleType.new(type_params.merge(custom: true))
        type.save!
        render_data type, VehicleTypeBlueprint, status: :created
      end

      def update
        type = authorize VehicleType.find(params[:id])
        type.update!(type_params)
        render_data type, VehicleTypeBlueprint
      end

      # Only custom types, and not while any company's trips use it (checked across every company).
      def destroy
        type = authorize VehicleType.find(params[:id])
        return render_error(:unprocessable_content, "Built-in types can't be removed. Companies turn them off instead") unless type.custom?

        ActsAsTenant.without_tenant do
          return render_error(:unprocessable_content, "This type is used by trips") if type.trip_vehicle_requirements.exists?

          type.destroy!
        end
        head :no_content
      end

      # PATCH /vehicle_types/:id/toggle { enabled } — the company turns a type on or off.
      def toggle
        type = authorize VehicleType.find(params[:id])
        if ActiveModel::Type::Boolean.new.cast(params.require(:enabled))
          DisabledVehicleType.where(vehicle_type: type).destroy_all
        else
          DisabledVehicleType.find_or_create_by!(vehicle_type: type)
        end
        render_data type, VehicleTypeBlueprint, disabled_ids:
      end

      private

      # { [seats, own?] => count } of the company's kept vehicles (matched by seats, as on the page).
      def fleet_counts
        return {} unless current_company

        Vehicle.kept.where.not(seats: nil).group(:seats, Arel.sql("vehicles.operator_id IS NULL")).count
      end

      def disabled_ids
        current_company ? DisabledVehicleType.pluck(:vehicle_type_id) : []
      end

      def type_params = params.expect(vehicle_type: %i[key name seats tyre_layout position])
    end
  end
end
