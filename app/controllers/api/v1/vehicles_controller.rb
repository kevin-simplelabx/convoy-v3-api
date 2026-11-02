# Vehicles, with the Scheduler's filters: ownership[] (own managed external), size[] (sedan mpv small medium large),
# tags[], vip, team_id, q (plate, make, model, driver, operator), sort (type | smallest | largest).
# meta.facets gives the counts for the filter chips (teams: chips of the Vehicles pages, by the ownership picked).
module Api
  module V1
    class VehiclesController < BaseController
      def index
        authorize Vehicle
        search = VehicleSearch.new(kept, params)
        render_page search.call, VehicleBlueprint, meta: { facets: search.facets, external_cap: }
      end

      # The vehicle record (list row fields plus upcoming driver changes, fuel and financials summaries).
      def show
        vehicle = authorize kept.find(params[:id])
        fuel = vehicle.own? ? FuelStatsPresenter.summary(FuelVehicleStats.new.call([ vehicle.id ])[vehicle.id]) : nil
        render_data vehicle, VehicleBlueprint, view: :record, vehfin: current_user.can?(:vehfin), fuel:
      end

      def create
        vehicle = authorize Vehicle.new(vehicle_params)
        vehicle.save!
        render_data vehicle, VehicleBlueprint, status: :created
      end

      def update
        vehicle = authorize kept.find(params[:id])
        vehicle.update!(vehicle_params)
        render_data vehicle, VehicleBlueprint
      end

      # Delete Vehicle: refused while the bus still has runs or workshop visits from now on.
      def destroy
        Vehicles::Remove.call(vehicle: authorize(kept.find(params[:id])))
        head :no_content
      end

      # POST /vehicles/external { plate, seats, driver_name, driver_phone, company: {name, phone, paynow_uen} }
      # New External Vehicle from the Scheduler: the hiring company is matched by name or created.
      def create_external
        authorize Vehicle, :create_external?
        vehicle = ExternalVehicles::Create.call(params: external_params, company: current_company, user: current_user)
        render_data vehicle, VehicleBlueprint, status: :created
      end

      private

      def kept = policy_scope(Vehicle).kept

      # External Vehicles: slots used against the company's cap.
      def external_cap
        used = Vehicle.external.kept.count
        limit = current_company.external_vehicle_cap
        { used:, limit:, left: [ limit - used, 0 ].max }
      end

      def vehicle_params = params.expect(vehicle: policy(Vehicle).permitted_attributes)

      def external_params
        params.permit(:plate, :seats, :driver_name, :driver_phone, :vehicle_id, :submission_id,
                      company: %i[name phone paynow_uen cost_per_trip cost_per_day valid_until])
      end
    end
  end
end
