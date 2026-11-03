# School Bus › Bus Fares › Extra Charges of an academic year: this year's charges and the ones carried over from earlier
# years, add / edit / delete (while Scheduled), Set End (while Active), and a preview of the next 4 bills.
module Api
  module V1
    class ExtraChargesController < BaseController
      # GET /academic_years/:academic_year_id/extra_charges
      def index
        year = find_year
        authorize year.school, :show?
        render json: { data: rows(year) }
      end

      # POST /academic_years/:academic_year_id/extra_charges { name, kind: pct|amt|once, value, from_month, to_month, targets: [], note }
      def create
        year = find_year
        authorize year.school, :money_setup?
        charge, warning = ExtraCharges::Save.call(year, charge_params, user: current_user)
        render json: { data: row(year, charge), meta: { warning: } }, status: :created
      end

      def update
        year = find_year
        authorize year.school, :money_setup?
        charge, warning = ExtraCharges::Save.call(year, charge_params, user: current_user, charge: find_charge(year))
        render json: { data: row(year, charge), meta: { warning: } }
      end

      def destroy
        year = find_year
        authorize year.school, :money_setup?
        charge = find_charge(year)
        raise ApplicationService::Error, "Only a charge that has not started can be deleted" unless charge.state == "scheduled"

        charge.destroy!
        head :no_content
      end

      # POST /academic_years/:academic_year_id/extra_charges/:id/end { to_month } — last month to charge.
      def end_charge
        year = find_year
        authorize year.school, :money_setup?
        charge = find_charge(year)
        raise ApplicationService::Error, "Only an active charge can be ended" unless charge.state == "active" && charge.kind != "once"

        to = Date.strptime(params.require(:to_month).to_s[0, 7], "%Y-%m")
        raise ApplicationService::Error, "Enter a month on or after #{charge.from_month.strftime('%Y-%m')}" if to < charge.from_month

        charge.update!(to_month: to)
        render json: { data: row(year, charge) }
      rescue Date::Error
        raise ApplicationService::Error, "Months must look like 2026-11"
      end

      # POST /academic_years/:academic_year_id/extra_charges/preview { …a draft charge, id when editing } — the next 4 bills
      # from its first month for its first target (or the first tier): before and after.
      def preview
        year = find_year
        authorize year.school, :show?
        render json: { data: ExtraCharges::Preview.call(year, charge_params, except_id: params[:id]) }
      end

      private

      def find_year = AcademicYear.where(school: policy_scope(School)).includes(:school, :terms, :holidays, :setup_locks).find(params[:academic_year_id])
      def find_charge(year) = year.school.fare_adjustments.where(academic_year: year).find(params[:id])

      def charge_params = params.permit(:name, :kind, :value, :from_month, :to_month, :note, targets: []).to_h.symbolize_keys

      def rows(year)
        own = year.school.fare_adjustments.where(academic_year: year).includes(:created_by).order(:from_month, :id).map { row(year, it) }
        carried = year.school.fare_adjustments.where.not(academic_year: year).where.not(kind: "once").includes(:academic_year)
                      .where(from_month: ...year.starts_on).where("to_month IS NULL OR to_month >= ?", year.starts_on).order(:from_month)
                      .map { row(year, it).merge(carried_from: it.academic_year.key, can_edit: false, can_delete: false, can_end: false) }
        own + carried
      end

      def row(year, c)
        writer = policy(year.school).money_setup?
        state = c.state
        { id: c.id, name: c.name, kind: c.kind, value: c.value, from_month: c.from_month.strftime("%Y-%m"), to_month: c.to_month&.strftime("%Y-%m"),
          targets: c.targets, note: c.note, state:, created_by: c.created_by&.name, created_at: c.created_at, carried_from: nil,
          can_edit: writer && state == "scheduled", can_delete: writer && state == "scheduled", can_end: writer && state == "active" && c.kind != "once" }
      end
    end
  end
end
