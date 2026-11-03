# School Bus › CCA Rides of a school: settings (charged per ride, price, days, seats), a week of CCA bus days with the
# rides booked in the Convoy App and its figures, and Bus Not Running (each ride that day becomes credit).
module Api
  module V1
    class CcaRidesController < BaseController
      # GET /schools/:school_id/cca_rides?week_of=YYYY-MM-DD (any day of the week; default the next week with rides)
      def show
        school = authorize find_school, :show?
        week = params[:week_of].present? ? CcaRides.monday(Date.parse(params[:week_of])) : CcaRides.default_week(school)
        render json: { data: CcaRides.week(school, week) }
      rescue Date::Error
        raise ApplicationService::Error, "Pick a date for the week"
      end

      # PUT /schools/:school_id/cca_rides { enabled, price, days: [1..5], seats }
      def update
        school = authorize find_school, :setup?
        CcaRides::SaveSettings.call(school, params.permit(:enabled, :price, :seats, days: []).to_h.symbolize_keys, user: current_user)
        render json: { data: CcaRides.week(school.reload, CcaRides.default_week(school)) }
      end

      # POST /schools/:school_id/cca_rides/not_running { date, reason: school | weather | bus | other | no_school, note }
      def not_running
        school = authorize find_school, :setup?
        n = CcaRides::NotRunning.call(school, date: params[:date], reason: params[:reason], note: params[:note], user: current_user)
        render json: { data: CcaRides.week(school, CcaRides.monday(Date.parse(params[:date].to_s))), meta: { credited: n } }
      end

      private

      def find_school = policy_scope(School).includes(cca_ride_setting: :saved_by).find(params[:school_id])
    end
  end
end
