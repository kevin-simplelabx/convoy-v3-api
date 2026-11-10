# School Bus › Route Plans: the engine's parameters (defaults from the routing service and the company's overrides),
# Run Routing for a school's session (a background run: poll it), and a run's state.
module Api
  module V1
    class RoutingController < BaseController
      # GET /routing/settings — { defaults, types, presets, effort, max_effort, engines } from the engine and the company's params.
      def settings
        authorize Stop, :index?
        meta = Routing::Client.current.meta
        render json: { data: meta.merge(params: RoutingSetting.first&.params || {}) }
      rescue Routing::Client::Unavailable => e
        raise ApplicationService::Error, "The routing service is not available (#{e.message})"
      end

      # PUT /routing/settings { params: { …engine parameters… } } — Save Parameters ({} = Convoy Defaults).
      def save_settings
        authorize Stop, :update?
        row = RoutingSetting.first_or_initialize
        row.update!(params: params.require(:params).permit!.to_h, updated_by: current_user)
        render json: { data: { params: row.params } }
      end

      # POST /schools/:school_id/routing_runs { session: am|pm|asa, date, params: { preset, effort, … } }
      def run
        authorize Stop, :update?
        school = policy_scope(School).find(params[:school_id])
        session = params.require(:session)
        raise ApplicationService::Error, "Pick AM, PM or ASA / CCA" unless SchoolPlan::SESSIONS.key?(session)
        raise ApplicationService::Error, "Place the school on the map first (postal code)" unless school.lat

        date = params[:date].present? ? Date.iso8601(params[:date]) : Date.current
        builder = Routing::Input.new(school, session, date, params: params.fetch(:params, {}).permit!.to_h)
        input = builder.call # with no rider at a stop the engine still runs: a plan with no routes, every rider unassigned (Convoy OS)
        run = RoutingRun.create!(school:, session:, plan_date: date, params: input[:params], input:, no_stop_rids: builder.no_stop,
                                 conflict_rids: builder.conflicts, created_by: current_user)
        RoutingRunJob.perform_later(run.id)
        render json: { data: run_row(run) }, status: :accepted
      rescue Date::Error
        raise ApplicationService::Error, "Date must look like 2026-11-02"
      end

      # GET /routing_runs/:id
      def show_run
        authorize Stop, :index?
        run = RoutingRun.where(school: policy_scope(School)).includes(:plan, :school).find(params[:id])
        render json: { data: run_row(run) }
      end

      private

      def run_row(run)
        { id: run.id, school_id: run.school_id, session: run.session, plan_date: run.plan_date, status: run.status, error: run.error,
          riders: run.input["groups"].sum { it["riders"].size }, stops: run.input["groups"].size,
          no_stop: Routing.rider_list(run.school, run.no_stop_rids), conflicts: Routing.rider_list(run.school, run.conflict_rids),
          ms: run.ms, plan_id: run.plan&.id, created_at: run.created_at, finished_at: run.finished_at, progress: progress(run) }
      end

      # The loader: the service's live progress while running; when done, the route options checked.
      def progress(run)
        case run.status
        when "running" then Routing::Client.current.progress(RoutingRun.progress_key(run.id))
        when "done" then { step: "done", frac: 1, work: { evals: run.result&.dig("search", "evals") } }
        end
      end
    end
  end
end
