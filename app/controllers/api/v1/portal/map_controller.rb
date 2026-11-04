# Client Portal › Map (today only): the activities (AM, PM, CCA school buses; Bookings; Shuttles), the runs of one with
# their state, bus and where it is, one run in detail (stops; students at each stop for a School Bus run), and finding
# a student.
module Api
  module V1
    module Portal
      class MapController < AppController
        # GET /portal/map?activity=am|pm|asa|bookings|shuttles&site_id=
        def show
          authorize_portal :shell, :show?
          render json: { data: map.call(activity: params[:activity]) }
        end

        # GET /portal/map/runs/:id
        def run
          authorize_portal :shell, :show?
          render json: { data: map.run(params[:id]) }
        end

        # GET /portal/map/students?q=
        def students
          authorize_portal :shell, :show?
          render json: { data: map.students(params[:q]) }
        end

        private

        def map = ::Portal::Map.new(client_user: current_client_user, site_id: params[:site_id])
      end
    end
  end
end
