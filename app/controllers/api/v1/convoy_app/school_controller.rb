# Convoy App › School Bus page, Bus Information and Live Tracking.
module Api
  module V1
    module ConvoyApp
      class SchoolController < SchoolBaseController
        # GET /app/school → { family, you, riders: [card], children: [card], address_change, actions }
        def show
          render json: { data: ::ConvoyApp::Parents::Page.new(current_member).call }
        end

        # GET /app/school/riders/:dependant_id/bus?session=am|pm → Bus Information
        def bus
          render json: { data: ::ConvoyApp::Parents::BusInfo.call(member: current_member, dependant_id: params[:dependant_id], session: params[:session]) }
        end

        # GET /app/school/live?bus=<key> → { state: none | far | near | ended, buses: [chip], bus } (live: TrackChannel school_live)
        #   The morning bus of the Family's children; position and path only in state near (10 min before the child's stop).
        def live
          render json: { data: ::ConvoyApp::Parents::Live.call(member: current_member, bus: params[:bus]) }
        end
      end
    end
  end
end
