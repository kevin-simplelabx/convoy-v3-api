# The push token of this phone (FCM), kept with the sign-in. Pushes carry the bell lines of every company the driver works
# for, so no company needs to be picked.
module Api
  module V1
    module DriverApp
      class DevicesController < BaseController
        # PUT /driver/device { device: { platform (ios|android), push_token } }
        def update
          attrs = params.expect(device: %i[platform push_token])
          DriverDevice.transaction do
            DriverDevice.where(push_token: attrs[:push_token]).where.not(driver_jwt_id: current_driver_jwt.id).delete_all
            device = current_driver_jwt.device || current_driver_jwt.build_device(driver_account: current_account)
            device.update!(attrs)
          end
          head :no_content
        end

        # DELETE /driver/device
        def destroy
          current_driver_jwt.device&.delete
          head :no_content
        end
      end
    end
  end
end
