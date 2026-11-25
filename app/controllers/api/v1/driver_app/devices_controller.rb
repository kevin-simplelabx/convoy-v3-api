# The push token of this phone (FCM), kept with the sign-in. Pushes carry the bell lines of every company the driver works
# for, so no company needs to be picked.
module Api
  module V1
    module DriverApp
      class DevicesController < BaseController
        # PUT /driver/device { device: { platform (ios|android), push_token } }
        def update
          DriverDevice.register!(current_driver_jwt, params.expect(device: %i[platform push_token]).to_h.symbolize_keys)
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
