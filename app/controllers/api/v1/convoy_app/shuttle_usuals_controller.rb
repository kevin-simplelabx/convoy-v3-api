# Convoy App › Shuttles › My Usual Shuttle (the sheet): one per employer.
module Api
  module V1
    module ConvoyApp
      class ShuttleUsualsController < ShuttleBaseController
        # GET /shuttles/:employer_id/usual → { employer, usual, routes: [{ id, name, directions: [{ direction, name, timings, stops }] }] }
        def show
          render json: { data: ::ConvoyApp::Shuttles::Usual.options(account: current_account, employer:) }
        end

        # PUT /shuttles/:employer_id/usual { trip_id, run_id, stop_id? } → same as show (422 "Pick your usual timing")
        def update
          ::ConvoyApp::Shuttles::Usual.save(account: current_account, employer:, trip_id: params.require(:trip_id), run_id: params[:run_id], stop_id: params[:stop_id])
          show
        end

        # DELETE /shuttles/:employer_id/usual (Clear) → same as show
        def destroy
          ::ConvoyApp::Shuttles::Usual.clear(account: current_account, employer:)
          show
        end
      end
    end
  end
end
