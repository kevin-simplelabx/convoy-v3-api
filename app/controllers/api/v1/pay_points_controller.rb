# HR > Points: drivers with their balance, a driver's balance card and history, Award / Deduct Points.
module Api
  module V1
    class PayPointsController < BaseController
      def index
        authorize :pay, :index?
        drivers = Driver.kept.active.order(:name).to_a
        live = DriverPointLot.live.where(driver_id: drivers.map(&:id)).group(:driver_id).sum(:remaining)
        buses = VehicleDriverSchedule.current_on(Date.current).where(driver_id: drivers.map(&:id)).includes(:vehicle).index_by(&:driver_id)
        render json: { data: drivers.map { |d| { id: d.id, name: d.name, plate: buses[d.id]&.vehicle&.plate, balance: live[d.id].to_i } } }
      end

      def show
        authorize :pay, :show?
        render_driver
      end

      # POST /pay/points/:driver_id { kind: award | deduct, points, reason }
      def create
        authorize :pay, :update?
        points = params.require(:points).to_i
        raise ApplicationService::Error, "Enter the number of points" unless points.positive?
        raise ApplicationService::Error, "Enter a reason" if params[:reason].to_s.strip.empty?

        ledger = Pay::Points.new(driver)
        args = { points:, reason: params[:reason].to_s.squish, user: current_user }
        params[:kind] == "deduct" ? ledger.deduct!(**args) : ledger.award!(**args)
        render_driver status: :created
      end

      private

      def driver = @driver ||= Driver.kept.find(params[:driver_id])

      def render_driver(status: :ok)
        ledger = Pay::Points.new(driver)
        render json: { data: { driver: { id: driver.id, name: driver.name }, **ledger.summary, history: ledger.history } }, status:
      end
    end
  end
end
