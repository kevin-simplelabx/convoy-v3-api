# Convoy Driver app GPS: the phone's points (a batch, sent every few seconds while a trip runs or is coming; queued when
# offline). They feed Live Map, Ops Control, School Live Ops, Trip History and tracking links, and confirm arrivals.
module Api
  module V1
    module DriverApp
      class PositionsController < BaseController
        before_action :require_membership!

        # POST /driver/positions { points: [{ at, lat, lng, speed_kmh, heading, accuracy_m, battery_pct, gsm_bars }] }
        def create
          points = params.permit(points: %i[at lat lng speed_kmh heading accuracy_m battery_pct gsm_bars passengers_count])[:points]
          raise ActionController::ParameterMissing, :points if points.nil?

          render json: { data: ::DriverApp::RecordPositions.call(jwt: current_driver_jwt, member: current_membership, points: points.map(&:to_h)) }
        end
      end
    end
  end
end
