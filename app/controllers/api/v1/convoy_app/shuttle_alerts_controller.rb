# Convoy App › Shuttle alerts: Alert Settings per route, the list on Account › Notifications, Pause Alerts (all routes).
module Api
  module V1
    module ConvoyApp
      class ShuttleAlertsController < ShuttleBaseController
        # GET /shuttles/alerts → { paused_until, routes: [{ employer, route, enabled, run_ids, weekdays, lead_minutes, notify, saved, timings }] }
        def index
          render json: { data: ::ConvoyApp::Shuttles::AlertSettings.list(account: current_account) }
        end

        # GET /shuttles/:employer_id/routes/:id/alerts → { route, employer, timings, setting, paused_until }
        def show
          render json: { data: ::ConvoyApp::Shuttles::AlertSettings.show(account: current_account, employer:, trip_id: params[:id]) }
        end

        # PUT /shuttles/:employer_id/routes/:id/alerts { enabled, run_ids, weekdays, lead_minutes, bus_change, service_days, late, notices } → same as show
        def update
          render json: { data: ::ConvoyApp::Shuttles::AlertSettings.save(account: current_account, employer:, trip_id: params[:id], params: alert_params) }
        end

        # PUT /shuttles/pause { until: "2026-12-01" } → { paused_until } (422 "Pick a date after today")
        def pause
          date = ::ConvoyApp::Shuttles::AlertSettings.pause(account: current_account, until_date: params.require(:until))
          render json: { data: { paused_until: date } }
        end

        # DELETE /shuttles/pause (Resume) → { paused_until: null }
        def resume
          ::ConvoyApp::Shuttles::AlertSettings.resume(account: current_account)
          render json: { data: { paused_until: nil } }
        end

        private

        def alert_params = params.permit(:enabled, :lead_minutes, :bus_change, :service_days, :late, :notices, run_ids: [], weekdays: [])
      end
    end
  end
end
