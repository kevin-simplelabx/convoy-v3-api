# School Bus › Route Plans › route drawer money and bus: the regular bus from a date, the operator's price history, and
# Route Charges (school pays per bus): the runs with their bus rate and extra, add a change, remove a scheduled one, and
# confirm / move / drop the charges carried to a new plan.
module Api
  module V1
    class RouteMoneyController < BaseController
      # POST /routes/:id/vehicle { vehicle_id (empty = no bus), from }
      def vehicle
        authorize Stop, :update?
        route = find_route
        from = day(:from) || route.plan.effective_from
        vehicle = params[:vehicle_id].present? ? Vehicle.kept.find(params[:vehicle_id]) : nil
        route.vehicle_changes.find_or_initialize_by(effective_from: from).update!(vehicle:, created_by: current_user)
        Plans.resync(route.plan) if route.plan.in_use
        render json: { data: history(route.reload) }
      end

      # PATCH /routes/:id/pay_setup { attendant_required, attendant_provided_by, attendant_price, pay_to: own|operator|"",
      # pay_to_operator_id } — BA settings need plans or finance; the BA price needs finance.
      def pay_setup
        authorize Stop, :pay_setup?
        money = policy(Stop).money_setup?
        route = find_route
        SchoolRoutes::PaySetup.call(route, params.permit(:attendant_required, :attendant_provided_by, :attendant_price, :pay_to, :pay_to_operator_id).to_h.symbolize_keys,
                                    money:)
        render json: { data: SchoolRouteBlueprint.pay_setup(route.reload) }
      end

      # GET /routes/:id/replacements — Replacement Buses of the route (latest first).
      def replacements
        authorize Stop, :index?
        render json: { data: replacement_rows(find_route) }
      end

      # POST /routes/:id/replacements { from, to, vehicle_id | plate + (operator_id | company), arranged_by: operator|us,
      # daily_rate, deduct, reason }
      def add_replacement
        authorize Stop, :update?
        route = find_route
        p = params.permit(:vehicle_id, :plate, :operator_id, :company, :arranged_by, :daily_rate, :deduct, :reason)
        vehicle = p[:vehicle_id].present? ? Vehicle.kept.find(p[:vehicle_id]) : nil
        SchoolRoutes::Replace.call(route:, from: day(:from), to: day(:to), user: current_user, vehicle:, plate: p[:plate], operator_id: p[:operator_id],
                                   company: p[:company], arranged_by: p[:arranged_by], daily_rate: p[:daily_rate], deduct: p.fetch(:deduct, true), reason: p[:reason])
        render json: { data: replacement_rows(route.reload) }, status: :created
      end

      # DELETE /route_replacements/:id — the route's regular bus comes back on those days (runs not started yet).
      def remove_replacement
        authorize Stop, :update?
        rep = SchoolRouteReplacement.where(route: SchoolRoute.where(plan: SchoolPlan.where(school: policy_scope(School)))).find(params[:id])
        route = rep.route
        rep.destroy!
        Occurrences::Sync.call(routes: [ route ], from: [ rep.starts_on, Date.current ].max, to: [ rep.ends_on, Date.current ].max)
        head :no_content
      end

      # DELETE /routes/:route_id/vehicle_changes/:change_id — Bus History "Remove this change" (not the first: the route's
      # bus from the start); the runs follow.
      def remove_vehicle
        authorize Stop, :update?
        route = find_route(params[:route_id])
        change = route.vehicle_changes.find(params[:change_id])
        raise ApplicationService::Error, "The first bus of the route cannot be removed. Change it instead" if change == route.vehicle_changes.min_by(&:effective_from)

        change.destroy!
        Plans.resync(route.plan) if route.plan.in_use
        render json: { data: history(route.reload) }
      end

      # DELETE /routes/:route_id/prices/:price_id — remove a price from the history (the one before, or the default, applies).
      def remove_price
        authorize Stop, :money_setup?
        route = find_route(params[:route_id])
        route.prices.find(params[:price_id]).destroy!
        render json: { data: history(route.reload) }
      end

      # POST /routes/:id/prices { effective_from, mode: fixed|rider, monthly, base_price, riders_included, per_rider }
      def price
        authorize Stop, :money_setup?
        route = find_route
        price = route.prices.find_or_initialize_by(effective_from: day(:effective_from) || Date.current.beginning_of_month)
        price.update!(params.permit(:mode, :monthly, :base_price, :riders_included, :per_rider).merge(created_by: current_user))
        render json: { data: history(route.reload) }
      end

      # GET /schools/:school_id/route_charges?date= — runs of the school's adopted plans with their bus rate and charges.
      def charges
        authorize Stop, :index?
        school = policy_scope(School).find(params[:school_id])
        date = day(:date) || Date.current
        year = school.academic_years.covering(date).includes(fare_table: :bus_rates).first
        rates = year&.fare_table&.per_bus? ? year.fare_table.bus_rates.to_h { [ it.bus_type, it.rate ] } : {}
        routes = SchoolRoute.joins(:plan).merge(school.plans.where(in_use: true, session: %w[am pm])).where("school_plans.effective_to IS NULL OR school_plans.effective_to >= ?", date)
                            .includes(:plan, :charges).order("school_plans.session", :number)
        render json: { data: { per_bus: rates.any?, runs: routes.map { run_row(it, rates, date) },
                               unmatched: school.route_charges_without_route.map { charge_row(it) },
                               to_check: RouteCharge.where(school:, status: "check").count } }
      end

      # POST /routes/:id/charges { starts_on, kind: amt|pct, value, reason, note } — value 0 ends the charge.
      def add_charge
        authorize Stop, :money_setup?
        route = find_route
        from = day(:starts_on) or raise ApplicationService::Error, "Pick the start date"
        raise ApplicationService::Error, "Pick a date from the 1st of this month" if from < Date.current.beginning_of_month

        RouteCharge.create!(school: route.school, school_route: route, starts_on: from, kind: params[:kind] || "amt", value: params.require(:value),
                            reason: params.require(:reason), note: params[:note], created_by: current_user)
        render json: { data: route.reload.charges.map { charge_row(it) } }, status: :created
      end

      # PATCH /route_charges/:id { school_route_id, status: "ok" } — confirm a carried charge, or move it to another run.
      def update_charge
        authorize Stop, :money_setup?
        charge = find_charge
        route_id = params[:school_route_id].presence
        route = route_id && SchoolRoute.where(plan: SchoolPlan.where(school: charge.school)).find(route_id)
        charge.update!(school_route: route || charge.school_route, status: params[:status] == "ok" ? "ok" : charge.status)
        render json: { data: charge_row(charge) }
      end

      # DELETE /route_charges/:id — a scheduled change (not started) or a carried charge being dropped.
      def remove_charge
        authorize Stop, :money_setup?
        charge = find_charge
        unless charge.status == "check" || charge.starts_on > Date.current
          raise ApplicationService::Error, "Only a change that has not started can be removed. Add a change of 0 to end it"
        end

        charge.destroy!
        head :no_content
      end

      private

      def find_route(id = params[:id])
        SchoolRoute.where(plan: SchoolPlan.where(school: policy_scope(School))).includes(:plan, :charges, :pay_to_operator, prices: :created_by, vehicle_changes: %i[vehicle created_by]).find(id)
      end
      def find_charge = RouteCharge.where(school: policy_scope(School)).find(params[:id])

      def day(key)
        params[key].present? ? Date.iso8601(params[key]) : nil
      rescue Date::Error
        raise ApplicationService::Error, "Dates must look like 2026-11-02"
      end

      def history(route)
        { vehicles: route.vehicle_changes.map { SchoolRouteBlueprint.vehicle_row(it) }, prices: route.prices.map { SchoolRouteBlueprint.price_row(it) } }
      end

      # A replacement with its school days (for "N school days x S$r = S$t").
      def replacement_rows(route)
        years = route.school.academic_years.includes(:terms, :holidays).to_a
        days = ->(r) { (r.starts_on..r.ends_on).count { |d| (y = years.find { it.starts_on <= d && d <= it.ends_on }) ? y.school_day?(d) : d.on_weekday? } }
        route.replacements.includes(:created_by, vehicle: :operator).sort_by { [ -it.starts_on.jd, -it.id ] }.map do |r|
          { id: r.id, starts_on: r.starts_on, ends_on: r.ends_on, vehicle: { id: r.vehicle_id, plate: r.vehicle.plate, seats: r.vehicle.seats },
            company: r.vehicle.operator&.name, arranged_by: r.arranged_by, daily_rate: r.daily_rate, deduct_from_operator: r.deduct_from_operator,
            reason: r.reason, school_days: days.(r), by: r.created_by&.shown_name, created_at: r.created_at }
        end
      end

      def run_row(route, rates, date)
        rate = rates[route.bus_type]
        now = RouteCharges.on(route, date)
        nxt = route.charges.select { it.starts_on > date }.min_by(&:starts_on)
        extra = now && rate ? now.amount(rate) : (now&.kind == "amt" ? now.value : 0)
        { route_id: route.id, plan_id: route.school_plan_id, session: route.plan.session, label: route.label, bus_type: route.bus_type, rate:,
          extra:, total: rate && (rate + extra), now: now && charge_row(now), next: nxt && charge_row(nxt), history: route.charges.map { charge_row(it) } }
      end

      def charge_row(c)
        { id: c.id, route_id: c.school_route_id, starts_on: c.starts_on, kind: c.kind, value: c.value, reason: c.reason, note: c.note, status: c.status,
          carried_from: c.carried_from_id }
      end
    end
  end
end
