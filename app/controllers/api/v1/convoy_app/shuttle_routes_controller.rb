# Convoy App › Shuttles › a route: the page, View Schedule, the pin and the stop bells.
module Api
  module V1
    module ConvoyApp
      class ShuttleRoutesController < ShuttleBaseController
        # GET /shuttles/:employer_id/routes/:id?date=&direction=1|2&run_id= → the route page (see .api-documents/convoy-app/shuttles.md)
        def show
          render json: { data: ::ConvoyApp::Shuttles::RoutePage.call(account: current_account, employer:, trip_id: params[:id], date: params[:date],
                                                                    direction: params[:direction], run_id: params[:run_id]) }
        end

        # GET /shuttles/:employer_id/routes/:id/schedule?month=YYYY-MM&date=&direction= → { days, timetable, … }
        def schedule
          render json: { data: ::ConvoyApp::Shuttles::Schedule.call(account: current_account, employer:, trip_id: params[:id], month: params[:month],
                                                                   date: params[:date], direction: params[:direction]) }
        end

        # PUT /shuttles/:employer_id/routes/:id/pin { pinned: true|false } → { pinned }
        def pin
          pinned = ::ConvoyApp::Shuttles::Marks.pin(account: current_account, employer:, trip_id: params[:id], pinned: boolean(:pinned))
          render json: { data: { pinned: } }
        end

        # PUT /shuttles/:employer_id/routes/:id/stops/:stop_id/bell { direction, on: true|false } → { on }
        def bell
          on = ::ConvoyApp::Shuttles::Marks.bell(account: current_account, employer:, trip_id: params[:id], stop_id: params[:stop_id],
                                                 direction: params.require(:direction), on: boolean(:on))
          render json: { data: { on: } }
        end

        private

        def boolean(key) = ActiveModel::Type::Boolean.new.cast(params.require(key))
      end
    end
  end
end
