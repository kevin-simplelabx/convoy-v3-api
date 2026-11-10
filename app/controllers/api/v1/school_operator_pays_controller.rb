# School Bus › Year Setup › Operator Pay of a school: settings and default prices per bus size, Save & Lock (Unlock:
# POST /schools/:id/unlock { section: "operator_pay" }), and the Break Month Calculator.
module Api
  module V1
    class SchoolOperatorPaysController < BaseController
      # GET /schools/:school_id/operator_pay — finance or finview (canFin in Convoy OS).
      def show
        school = find_school
        authorize school, :money_view?
        render json: { data: payload(school) }
      end

      # PUT /schools/:school_id/operator_pay { scheme, paid_months, part_pct, part_basis, break_months, break_pay, earn_by,
      #   grace_start_days, deduct_days, rates: [{ bus_type, fixed_on, monthly, rider_on, base_price, riders_included, per_rider,
      #   default_mode, ba_operator, ba_us }] }
      def update
        school = authorize find_school, :money_setup?
        OperatorPays::Save.call(school, pay_params, user: current_user)
        render json: { data: payload(find_school) }
      end

      # POST /schools/:school_id/operator_pay/calculator { academic_year_id, start_date, price }
      def calculator
        school = find_school
        authorize school, :money_view?
        year = school.academic_years.includes(:terms, :holidays).find(params.require(:academic_year_id))
        settings = school.operator_pay || school.build_operator_pay
        start = Date.iso8601(params.require(:start_date))
        render json: { data: OperatorPays::Calculator.new(school, year, settings).call(start:, price: params[:price].presence) }
      rescue Date::Error
        raise ApplicationService::Error, "Pick a start date"
      end

      private

      def find_school = policy_scope(School).includes(:bus_size_rates, :setup_locks, operator_pay: :updated_by).find(params[:school_id])

      def payload(school)
        s = school.operator_pay || school.build_operator_pay
        lock = school.setup_locks.find { it.section == "operator_pay" && it.academic_year_id.nil? }
        rates = school.bus_size_rates.index_by(&:bus_type)
        { saved: s.persisted?, locked: lock && { at: lock.locked_at, by: lock.locked_by&.name },
          **s.slice(:scheme, :paid_months, :part_pct, :part_basis, :break_months, :break_pay, :earn_by, :grace_start_days, :deduct_days).symbolize_keys,
          rates: SchoolBus.types(school).map do |t|
            k = t[:key]
            r = rates[k]
            { bus_type: k, label: t[:label], seats: t[:seats], student_seats: t[:student_seats], ba_required: t[:student_seats] < t[:seats],
              fixed_on: r ? r.fixed_on : true, monthly: r&.monthly, rider_on: r&.rider_on || false, base_price: r&.base_price,
              riders_included: r&.riders_included, per_rider: r&.per_rider, default_mode: r&.default_mode || "fixed", ba_operator: r&.ba_operator, ba_us: r&.ba_us }
          end }
      end

      def pay_params
        cast = ->(v) { ActiveModel::Type::Boolean.new.cast(v) || false }
        p = params.permit(:scheme, :part_pct, :part_basis, :break_pay, :earn_by, :grace_start_days, :deduct_days, paid_months: [], break_months: [],
                          rates: %i[bus_type fixed_on monthly rider_on base_price riders_included per_rider default_mode ba_operator ba_us]).to_h.deep_symbolize_keys
        p[:rates] = Array(p[:rates]).map { |r| r.merge(fixed_on: cast.(r[:fixed_on]), rider_on: cast.(r[:rider_on])) }
        p
      end
    end
  end
end
