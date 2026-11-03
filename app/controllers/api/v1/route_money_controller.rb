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

      def find_route = SchoolRoute.where(plan: SchoolPlan.where(school: policy_scope(School))).includes(:plan, :prices, :charges, vehicle_changes: :vehicle).find(params[:id])
      def find_charge = RouteCharge.where(school: policy_scope(School)).find(params[:id])

      def day(key)
        params[key].present? ? Date.iso8601(params[key]) : nil
      rescue Date::Error
        raise ApplicationService::Error, "Dates must look like 2026-11-02"
      end

      def history(route)
        { vehicles: route.vehicle_changes.map { { from: it.effective_from, vehicle_id: it.vehicle_id, plate: it.vehicle&.plate } },
          prices: route.prices.map { it.slice(:effective_from, :mode, :monthly, :base_price, :riders_included, :per_rider) } }
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
