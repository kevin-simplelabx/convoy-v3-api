# School Bus › Route Plans › route drawer and map tools: a route's stops and riders (re-timed), New Route, bus type,
# lock / hide, attendant, delete, Reset Route; Route Again on a plan (a background run like Run Routing).
module Api
  module V1
    class SchoolRoutesController < BaseController
      # PUT /routes/:id/stops { stops: [{ stop_point_id, riders: [rid] }], vias: [[[lat, lng], …], …] }
      def update_stops
        route = find
        authorize Stop, :update?
        Plans::Edit.new(route.plan).set_stops(route, stop_entries, vias: params[:vias])
        render_plan(route.plan)
      end

      # POST /plans/:plan_id/routes { bus_type, stops: [{ stop_point_id, riders }] } — New Route (locked, drawn by hand).
      def create
        plan = find_plan
        authorize Stop, :update?
        Plans::Edit.new(plan).add_route(stop_entries, type: params.require(:bus_type))
        render_plan(plan, status: :created)
      end

      # PATCH /routes/:id { route: { bus_type, locked, hidden, attendant_id } }
      def update
        route = find
        authorize Stop, :update?
        p = params.expect(route: %i[bus_type locked hidden attendant_id])
        Plans::Edit.new(route.plan).change_type(route, p[:bus_type]) if p[:bus_type].present? && p[:bus_type] != route.bus_type
        route.update!(p.slice(:locked, :hidden, :attendant_id))
        render_plan(route.plan)
      end

      def destroy
        route = find
        authorize Stop, :update?
        Plans::Edit.new(route.plan).remove_route(route)
        render_plan(route.plan)
      end

      # POST /routes/:id/reset
      def reset
        route = find
        authorize Stop, :update?
        Plans::Edit.new(route.plan).reset(route)
        render_plan(route.plan)
      end

      # POST /plans/:plan_id/route_again { params: {…}, fleet: { MEDIUM_23: 2, SMALL_13: 0 } }
      def route_again
        plan = find_plan
        authorize Stop, :update?
        keep = plan.routes.where(locked: true).joins(:riders).pluck("school_route_riders.rid").to_set
        overrides = params.fetch(:params, {}).permit!.to_h
        builder = Routing::Input.new(plan.school, plan.session, plan.effective_from, params: (plan.params || {}).merge(overrides))
        input = builder.call
        input[:groups] = input[:groups].filter_map { |g| g.merge(riders: g[:riders].reject { keep.include?(it) }).then { it[:riders].empty? ? nil : it } }
        raise ApplicationService::Error, "Every rider is on a locked route. Unlock a route to route again" if input[:groups].empty?

        fleet = params.fetch(:fleet, {}).permit!.to_h
        if fleet.any?
          types = Array(input[:params]["types"].presence || Routing::Client.current.meta["types"])
          input[:params] = input[:params].merge("types" => types.map { |t| fleet.key?(t["type"]) ? t.merge(fleet[t["type"]].to_i.zero? ? { "on" => false } : { "max" => fleet[t["type"]].to_i }) : t })
        end
        run = RoutingRun.create!(school: plan.school, session: plan.session, plan_date: plan.effective_from, params: input[:params], input:, kind: "again",
                                 target_plan: plan, no_stop_rids: builder.no_stop, conflict_rids: builder.conflicts, created_by: current_user)
        RoutingRunJob.perform_later(run.id)
        render json: { data: { id: run.id, status: run.status, kind: run.kind, plan_id: plan.id } }, status: :accepted
      end

      private

      def plans = SchoolPlan.where(school: policy_scope(School))
      def find = SchoolRoute.where(plan: plans).includes(:plan).find(params[:id])
      def find_plan = plans.find(params[:plan_id])

      def stop_entries
        params.permit(stops: [ :stop_point_id, { riders: [] } ]).to_h.deep_symbolize_keys.fetch(:stops, [])
      end

      def render_plan(plan, status: :ok)
        full = SchoolPlan.includes(*SchoolPlansController::INCLUDES).find(plan.id)
        render_data full, SchoolPlanBlueprint, view: :detail, status:
      end
    end
  end
end
