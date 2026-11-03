# Convoy Driver app › Switch Vehicle: the handover inspection (six photos, marked up where needed, and the declaration).
module Api
  module V1
    module DriverApp
      class VehicleHandoversController < BaseController
        before_action :require_membership!

        # POST /driver/vehicle/handovers (multipart) { client_id, vehicle_id, at, declaration, note,
        #   photos[front|left|right|back|odometer|inside], marked[side], marks[side] }
        def create
          handover, replayed = ::DriverApp::Handover.call(account: current_account, member: current_membership,
                                                         params: params.except(:controller, :action, :format).permit!)
          render json: { data: DriverHandoverBlueprint.render_as_hash(VehicleHandover.includes(:vehicle, :photos).find(handover.id)),
                         meta: { replayed: } }, status: replayed ? :ok : :created
        end
      end
    end
  end
end
