# Reports > Shuttle Report: clients with Corporate Shuttle routes and the period options, the report of a route and
# period, and the month grids (riders per timing per day, on-time per stop). A stop record opens Trip History.
module Api
  module V1
    class ReportsController < BaseController
      # GET /reports/shuttle/options
      def options
        authorize :report, :index?
        trips = Trip.kept.where(kind: "corporate_shuttle").includes(:client).order(:title).to_a
        clients = trips.group_by(&:client).sort_by { |c, _| c.name }.map do |client, list|
          { id: client.id, name: client.name, on_time_allowance: client.on_time_allowance,
            routes: list.map { |t| { id: t.id, title: t.title, ref: t.decorate.trip_id } } }
        end
        render json: { data: { clients:, periods: Reports::Shuttle.options } }
      end

      # GET /reports/shuttle?trip_id=&period=m|2026-10
      def shuttle
        authorize :report, :show?
        render json: { data: Reports::Shuttle.new(trip:, period: params[:period]).summary }
      end

      # GET /reports/shuttle/grid?trip_id=&month=2026-10
      def grid
        authorize :report, :show?
        month = Date.strptime(params.require(:month), "%Y-%m")
        render json: { data: Reports::Shuttle.new(trip:, period: "m|#{params[:month]}").grid(month) }
      rescue Date::Error
        raise ApplicationService::Error, "Month must look like 2026-10"
      end

      private

      def trip = Trip.kept.where(kind: "corporate_shuttle").includes(:client, :stops).find(params.require(:trip_id))
    end
  end
end
