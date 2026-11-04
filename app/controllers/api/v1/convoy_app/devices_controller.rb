# The push token of this phone (FCM / APNs), kept with the sign-in; nothing is pushed yet.
module Api
  module V1
    module ConvoyApp
      class DevicesController < BaseController
        skip_before_action :require_profile!

        # PUT /app/device { platform (ios|android), push_token }
        def update
          attrs = params.expect(device: %i[platform push_token])
          AppDevice.transaction do
            AppDevice.where(push_token: attrs[:push_token]).where.not(app_jwt_id: current_app_jwt.id).delete_all
            device = current_app_jwt.devices.first_or_initialize(app_account: current_account)
            device.update!(attrs)
          end
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
