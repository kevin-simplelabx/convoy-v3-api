# Convoy App › Pick a Point: the organisation's points, My Points (Home on Personal) and Recent; Save This Point.
module Api
  module V1
    module ConvoyApp
      class BookingPointsController < BookingBaseController
        # GET /app/bookings/points?account= → { org_name, can_save_org, org, mine, recent }
        def index
          render json: { data: within { ::ConvoyApp::Bookings::Points.call(account) } }
        end

        # POST /app/bookings/points { account, to: me | org, name, address, lat, lng, note } → point (201)
        def create
          point = within { ::ConvoyApp::Bookings::Points.save!(account, params.permit(:to, :name, :address, :lat, :lng, :note)) }
          render json: { data: point }, status: :created
        end
      end
    end
  end
end
