# Ops Control: the board of runs with a first pick-up in the next 2 hours (checked now, alerts kept in step), the Alert Log
# of today, and Acknowledge on a run.
module Api
  module V1
    class OpsControlController < BaseController
      LOG_LIMIT = 60

      # GET /ops_control?tab=needs_action|all|not_started|running|ended&client_id=&q=&sort=asc|desc
      def index
        authorize :ops_control, :index?
        checks = OpsControl::Sync.call
        data = OpsControl::Board.new(checks).call(tab: params[:tab], client_id: params[:client_id], q: params[:q], sort: params[:sort])
        render json: { data:, meta: { now: Time.current, duty: current_user.name, rules: OpsControl.rules } }
      end

      # GET /ops_control/log — alerts raised today, newest first (60).
      def log
        authorize :ops_control, :index?
        alerts = OpsAlert.where(raised_at: Time.current.beginning_of_day..).order(raised_at: :desc).limit(LOG_LIMIT)
                         .includes(:acknowledged_by, occurrence: %i[vehicle client trip school_route]).to_a
        render json: { data: alerts.map { |a| log_row(a) }, meta: { count: alerts.size } }
      end

      # POST /ops_control/runs/:id/acknowledge
      def acknowledge
        authorize :ops_control, :acknowledge?
        occ = policy_scope(TripOccurrence).find(params[:id])
        render json: { data: OpsControl::Acknowledge.call(occ, current_user) }
      end

      private

      def log_row(a)
        o = a.occurrence
        { id: a.id, occurrence_id: a.occurrence_id, kind: a.kind, severity: a.severity, message: a.message, raised_at: a.raised_at,
          plate: o&.vehicle&.plate, title: o&.decorate&.title, trip_label: o&.trip_label, client: o&.client&.name,
          status: a.log_status, acknowledged_at: a.acknowledged_at, acknowledged_by: a.acknowledged_by&.name,
          escalated_at: a.escalated_at, cleared_at: a.cleared_at }
      end
    end
  end
end
