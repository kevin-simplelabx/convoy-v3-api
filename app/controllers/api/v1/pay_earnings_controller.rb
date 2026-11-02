# HR > Earnings: each driver's pay this month from the Scheduler, the runs and the breakdown, Confirm / Reopen Month.
module Api
  module V1
    class PayEarningsController < BaseController
      # GET /pay/earnings?month=2026-10&q=
      def index
        authorize :pay, :index?
        drivers = Driver.kept.where(id: Driver.kept.active.select(:id)).or(Driver.kept.where(id: TripOccurrence.in_month(month).select(:driver_id))).order(:name)
        drivers = drivers.where("drivers.name ILIKE ?", "%#{Driver.sanitize_sql_like(params[:q].to_s.strip)}%") if params[:q].present?
        rows = drivers.map { |d| Pay::DriverMonth.call(driver: d, month:) }
        vehicles = VehicleDriverSchedule.current_on([ month.end_of_month, Date.current ].min).where(driver_id: drivers.map(&:id)).includes(:vehicle)
                                        .to_h { |s| [ s.driver_id, s.vehicle ] }
        list = PayEarningBlueprint.render_as_hash(rows, vehicles:)
        render json: { data: list, meta: { month: month.strftime("%Y-%m"), completed: list.sum { |r| r[:completed] }, held: list.sum { |r| r[:held] },
                                           total: list.sum { |r| r[:total].to_d }, confirmed: list.count { |r| r[:status] == "confirmed" }, drivers: list.size } }
      end

      # GET /pay/earnings/:driver_id?month=
      def show
        authorize :pay, :show?
        render_month
      end

      # POST /pay/earnings/:driver_id/confirm?month=
      def confirm
        authorize :pay, :update?
        Pay::ConfirmMonth.call(driver:, month:, user: current_user)
        render_month
      end

      # DELETE /pay/earnings/:driver_id/confirm?month= — Reopen Month (Admin)
      def reopen
        authorize :pay, :reopen?
        record = DriverPayMonth.find_by!(driver:, month:)
        DriverPayMonth.transaction do
          lots = DriverPointLot.where(driver_pay_month: record)
          raise ApplicationService::Error, "Points from this month's bonuses are already used, so it can't be reopened" if lots.any? { |l| l.remaining < l.points }

          lots.destroy_all
          record.audit_comment = "Reopened #{month.strftime('%b %Y')}"
          record.destroy!
        end
        render_month
      end

      private

      def driver = @driver ||= Driver.kept.find(params[:driver_id])

      def month
        @month ||= Date.strptime(params[:month].presence || Date.current.strftime("%Y-%m"), "%Y-%m")
      rescue Date::Error
        raise ApplicationService::Error, "Month must look like 2026-11"
      end

      def render_month
        out = Pay::DriverMonth.call(driver:, month:)
        vehicles = { driver.id => driver.vehicle_on([ month.end_of_month, Date.current ].min) }.compact
        render json: { data: PayEarningBlueprint.render_as_hash(out, view: :detail, vehicles:) }
      end
    end
  end
end
