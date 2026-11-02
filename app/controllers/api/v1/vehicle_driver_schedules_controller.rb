# Default driver schedule of an own vehicle: history with periods, change from a date (can be ahead),
# remove an upcoming change. Occurrences on the vehicle follow it (sync arrives with the occurrence engine).
module Api
  module V1
    class VehicleDriverSchedulesController < BaseController
      before_action :set_vehicle

      def index
        authorize VehicleDriverSchedule
        entries = @vehicle.driver_schedules.includes(:driver).to_a
        ends = entries.each_cons(2).to_h { |a, b| [ a.id, b.starts_on - 1 ] }
        render_list entries, VehicleDriverScheduleBlueprint, ends:
      end

      # POST { driver_id, starts_on } — the same date again replaces that entry.
      def create
        entry = @vehicle.driver_schedules.find_or_initialize_by(starts_on: entry_params[:starts_on])
        entry.assign_attributes(driver_id: entry_params[:driver_id], created_by: current_user)
        authorize(entry).save!
        render_data entry, VehicleDriverScheduleBlueprint, status: :created
      end

      def destroy
        authorize(@vehicle.driver_schedules.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_vehicle
        @vehicle = Vehicle.kept.own.find(params[:vehicle_id])
      end

      def entry_params = params.expect(vehicle_driver_schedule: %i[driver_id starts_on])
    end
  end
end
