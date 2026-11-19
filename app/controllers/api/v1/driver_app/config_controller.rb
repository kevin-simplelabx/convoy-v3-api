# Convoy Driver app settings from the server: the GPS profile (the same for every company) and the driving rules the app
# shows before the server answers (start window, late warning), and the reason lists.
module Api
  module V1
    module DriverApp
      class ConfigController < BaseController
        # GET /driver/config
        def show
          drive = ::DriverApp::Drive
          company = current_membership&.company
          render json: { data: {
            gps: ::DriverApp::Gps::PROFILE,
            start_early_minutes: (drive::START_EARLY / 60).to_i, late_warning_minutes: 30,
            pickup_grace_minutes: company&.pickup_grace_minutes || Company.column_defaults["pickup_grace_minutes"],
            reasons: { skip_stop: drive::SKIP_STOP_REASONS, skip_trip: drive::SKIP_TRIP_REASONS, force_end: drive::FORCE_END_REASONS },
            date_format: company&.date_format, time_format: company&.time_format
          } }
        end
      end
    end
  end
end
