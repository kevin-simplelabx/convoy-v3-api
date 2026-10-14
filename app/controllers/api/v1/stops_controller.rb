module Api
  module V1
    class StopsController < BaseController
      before_action :require_company!
      before_action -> { require_permission!("plans") }, only: [ :update ]

      # GET /api/v1/stops
      def show
        sl = StopLibrary.for_company(current_company)
        render json: { lib: sl.lib, counters: sl.counters }
      end

      # PUT /api/v1/stops
      def update
        sl  = StopLibrary.for_company(current_company)
        lib = Array(params[:lib])

        # Non-library managers cannot approve stops on their own
        unless current_user.has_permission?("library")
          lib = lib.map do |stop|
            existing = sl.lib.find { |s| s["uid"] == stop["uid"] }
            if stop["libStatus"] == "approved" && existing&.dig("libStatus") != "approved"
              stop.merge("libStatus" => "pending")
            else
              stop
            end
          end
        end

        sl.update!(
          lib:      lib,
          counters: params[:counters].present? ? params[:counters].to_unsafe_h : sl.counters
        )
        render json: { ok: true }
      end
    end
  end
end
