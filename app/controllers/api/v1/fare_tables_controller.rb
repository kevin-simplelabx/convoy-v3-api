# School Bus › Year Setup › Bus Fares of an academic year: the table (as the wizard sends it), its billing periods and
# the fares worked out per tier and bill; Save & Lock; another year's table as a draft.
# Unlock: POST /academic_years/:id/unlock { section: "fares" }.
module Api
  module V1
    class FareTablesController < BaseController
      INCLUDES = { tiers: :sizes, size_columns: [], surcharges: [], bus_rates: [] }.freeze

      # GET /academic_years/:academic_year_id/fares
      def show
        year = find_year
        authorize year.school, :show?
        render json: { data: payload(year) }
      end

      # PUT /academic_years/:academic_year_id/fares { …the whole table, see the API guide… }
      def update
        year = find_year
        authorize year.school, :money_setup?
        FareTables::Save.call(year, table_params, user: current_user)
        render json: { data: payload(find_year) }
      end

      # GET /academic_years/:academic_year_id/fares/copy?from_id= — another year's table as a draft (not saved).
      def copy
        year = find_year
        authorize year.school, :money_setup?
        from = year.school.academic_years.find(params.require(:from_id)).fare_table or raise ApplicationService::Error, "That year has no fares yet"
        render json: { data: FareTables::Present.call(from).merge(period_snapshot: nil) }
      end

      private

      def find_year
        AcademicYear.where(school: policy_scope(School)).includes(:school, :terms, :holidays, { setup_locks: :locked_by }, fare_table: INCLUDES)
                    .find(params[:academic_year_id])
      end

      def payload(year)
        table = year.fare_table
        periods = FareTables.periods(year)
        lock = year.lock_of(:fares)
        { table: table && FareTables::Present.call(table), locked: lock && { at: lock.locked_at, by: lock.locked_by&.name },
          calendar_locked: year.lock_of(:calendar).present?, periods:, fares: table ? FareTables::Calc.call(table, periods) : [],
          bus_types: SchoolBus::BUS_TYPES.map { |k, t| { key: k, label: t[:label], seats: t[:seats] } } }
      end

      def table_params
        prices = [ :fare, :pm_fare, :one_way_fare, { period_fares: [], period_pm_fares: [] } ]
        area = [ :area, { area: [] } ]
        params.permit(
          :payer, :basis, :trip, :cycle, :distribution, :by_size, :bus_count, { months: [] }, { bill_to: %i[name contact email] },
          { one_way: %i[type value] }, { size_columns: [ :max_seats ] },
          { tiers: [ :max_km, :name, :small_fare, :express_fare, :cca_fare, :sectors, { sectors: [] }, *area, *prices, { sizes: prices } ] },
          { surcharges: [ :name, :kind, :amount, :one_way_kind, :one_way_value, :sectors, { sectors: [] }, *area ] },
          { small: %i[on type value seats] }, { express: %i[on type value] },
          { cca: [ :on, :per, :price, :fixed, :split, :with_services, { riders: { non: %i[on type amount], am: %i[on type amount], pm: %i[on type amount] } } ] },
          { bus_rates: %i[bus_type rate booked_runs] }
        ).to_h.deep_symbolize_keys.tap { |f| bools!(f) }
      end

      def bools!(f)
        cast = ->(v) { ActiveModel::Type::Boolean.new.cast(v) || false }
        f[:by_size] = cast.(f[:by_size])
        %i[small express cca].each { |k| f[k][:on] = cast.(f[k][:on]) if f[k] }
        f[:cca][:with_services] = cast.(f[:cca][:with_services]) if f[:cca]
        (f.dig(:cca, :riders) || {}).each_value { it[:on] = cast.(it[:on]) }
      end
    end
  end
end
