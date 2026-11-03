# Default driver schedule of an own vehicle: history with periods, change from a date (can be ahead),
# remove an upcoming change. Occurrences on the vehicle follow it (sync arrives with the occurrence engine).
module Api
  module V1
    class VehicleDriverSchedulesController < BaseController
      before_action :set_vehicle

      def index
        authorize VehicleDriverSchedule
        entries = @vehicle.driver_schedules.includes(:driver).sort_by(&:sort_key)
        # the next entry ends this one: the day before, or the same day at its start time
        ends = entries.each_cons(2).to_h do |a, b|
          [ a.id, b.start_time.positive? ? { on: b.starts_on, at: b.start_time_hm } : { on: b.starts_on - 1, at: nil } ]
        end
        render_list entries, VehicleDriverScheduleBlueprint, ends:
      end

      # POST { driver_id, starts_on, start_time } — the same date and time again replaces that entry. start_time
      # (HH:MM, default 00:00 = the whole day): runs on the bus from then take the driver.
      def create
        entry = @vehicle.driver_schedules.find_or_initialize_by(starts_on: entry_params[:starts_on], start_time: start_minute)
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

      def start_minute
        Clock.minutes(entry_params[:start_time].presence || 0)
      rescue ArgumentError
        raise ApplicationService::Error.new("Start time must be a time like 07:30", details: { start_time: [ "must be a time like 07:30" ] })
      end

      def entry_params = params.expect(vehicle_driver_schedule: %i[driver_id starts_on start_time])
    end
  end
end
