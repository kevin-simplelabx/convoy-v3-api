# Convoy Driver app › Account › My Vehicle Today (and the plate on Drive), Switch Vehicle and Vehicle History, at the
# company picked for the sign-in.
module Api
  module V1
    module DriverApp
      class VehicleController < BaseController
        before_action :require_membership!

        # GET /driver/vehicle → { current, switches, handovers } — the bus now, the buses to take over later today or tomorrow,
        # and today's handovers.
        def show
          current = ::DriverApp::Vehicles.current(current_membership)
          today = handovers.where(at: Date.current.all_day).to_a
          render json: { data: {
            current: current && DriverVehicleBlueprint.render_as_hash(current.merge(vehicle: current[:vehicle].decorate)),
            switches: ::DriverApp::Vehicles.switches(current_membership).map { switch(it, today) },
            handovers: DriverHandoverBlueprint.render_as_hash(today)
          } }
        end

        # GET /driver/vehicle/history?month=YYYY-MM → the buses driven each day (from the runs) and the handovers
        def history
          month = params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current.beginning_of_month
          runs = ::DriverApp::Runs.scope(current_membership).where(date: month..month.end_of_month).where.not(status: "cancelled")
                                  .includes(:vehicle).to_a.select { ::DriverApp::Runs.mine?(it, current_membership) && it.vehicle }
          days = runs.group_by(&:date).sort.map do |date, list|
            { date:, vehicles: list.group_by(&:vehicle).map { |v, l| { id: v.id, plate: v.plate, runs: l.size } } }
          end
          render json: { data: { month: month.strftime("%Y-%m"), days:,
                                 handovers: DriverHandoverBlueprint.render_as_hash(handovers.where(at: month.all_month).to_a) } }
        rescue Date::Error
          render_error(:unprocessable_content, "Months are YYYY-MM")
        end

        private

        def handovers
          col = current_membership.is_a?(OperatorDriver) ? :operator_driver_id : :driver_id
          VehicleHandover.where(col => current_membership.id).includes(:vehicle, :photos).order(:at)
        end

        def switch(entry, today)
          { vehicle: DriverVehicleBlueprint.render_as_hash({ vehicle: entry[:vehicle].decorate, since: nil, since_time: nil }),
            starts_at: entry[:starts_at], handover_done: today.any? { it.vehicle_id == entry[:vehicle].id } }
        end
      end
    end
  end
end
