# The push token of this phone (FCM), kept with the sign-in; new inbox alerts are pushed to it (Push::AppAlerts).
module Api
  module V1
    module ConvoyApp
      class DevicesController < BaseController
        skip_before_action :require_profile!

        # PUT /app/device { platform (ios|android), push_token }
        def update
          AppDevice.register!(current_app_jwt, params.expect(device: %i[platform push_token]).to_h.symbolize_keys)
          head :no_content
        end

        # DELETE /app/device
        def destroy
          current_app_jwt.devices.delete_all
          head :no_content
        end
      end
    end
  end
end
