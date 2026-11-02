# Own drivers (Fleet > Drivers): tabs by status, invite with name and mobile, edit, the invite lifecycle,
# View Details and the customer-facing copy (DriverInviteActions).
module Api
  module V1
    class DriversController < BaseController
      include DriverInviteActions

      private

      def driver_class = Driver
      def driver_blueprint = DriverBlueprint
      def driver_includes = %i[last_vehicle display_set_by kyc_profile]

      # Bus today with the date it started, upcoming default driver changes, last bus of past drivers.
      def list_options(drivers)
        ids = Array(drivers).map(&:id)
        today = VehicleDriverSchedule.current_on(Date.current).where(driver_id: ids).includes(:vehicle).index_by(&:driver_id)
        upcoming = VehicleDriverSchedule.upcoming.where(driver_id: ids).includes(:vehicle).order(:starts_on).group_by(&:driver_id)
        { today:, upcoming: }
      end

      def driver_params = params.expect(driver: %i[name phone photo remove_photo])
    end
  end
end
