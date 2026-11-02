# Notices page and Send Notice (trip drawer): tabs Active, Scheduled, Ended with search; End Now (active), Edit (scheduled),
# Duplicate, Delete (not active).
module Api
  module V1
    class NoticesController < BaseController
      FIELDS = %i[audience trip_id school_id to_riders to_parents banner push sms whatsapp starts_at ends_at notice_template_id message].freeze

      INCLUDES = [ :created_by, :ended_by, :deliveries, :school, :route_targets, { trip: :client, runs: :trip_run } ].freeze

      # GET /notices?state=active|scheduled|ended &q= &trip_id= — the Notices page (meta.counts: the three tabs).
      # Active and Scheduled: soonest start first; Ended: latest end first.
      def index
        authorize Notice
        now = Time.current
        base = policy_scope(Notice).search(params[:q])
        base = base.where(trip_id: params[:trip_id]) if params[:trip_id].present?
        scope = base.in_state(params[:state], now).includes(*INCLUDES)
        scope = case params[:state]
        when "ended" then scope.order(Arel.sql("COALESCE(notices.ended_at, notices.ends_at) DESC"))
        when "active", "scheduled" then scope.order(:starts_at)
        else scope.order(starts_at: :desc)
        end
        render_page scope, NoticeBlueprint, meta: { counts: Notice::STATES.index_with { |st| base.in_state(st, now).count } }
      end

      def show
        render_data authorize(find), NoticeBlueprint
      end

      # POST { notice: {...}, start: now | at, period_minutes, run_keys: ["all"] | ["d1r0", ...] }
      def create
        save(authorize(Notice.new), :created)
      end

      def update
        save(authorize(find), :ok)
      end

      def end_now
        notice = authorize find
        raise ApplicationService::Error, "Only an active notice can be ended" unless notice.state == "active"

        notice.update!(ended_at: Time.current, ended_by: current_user)
        render_data notice, NoticeBlueprint
      end

      # A copy to send again, starting now for the same length of time.
      def duplicate
        src = authorize find, :duplicate?
        copy = src.dup.tap do |n|
          n.assign_attributes(starts_at: Time.current, ends_at: Time.current + (src.ends_at - src.starts_at), ended_at: nil,
                              ended_by: nil, created_by: current_user)
          src.runs.each { |r| n.runs.build(trip_run: r.trip_run) }
        end
        copy.save!
        render_data copy, NoticeBlueprint, status: :created
      end

      def destroy
        authorize(find).destroy!
        head :no_content
      end

      private

      def find = find_by(params[:id])

      def save(notice, status)
        attrs = params.require(:notice).permit(*FIELDS)
        Notices::Save.call(notice:, attributes: attrs, user: current_user, start: params[:start] || (notice.new_record? ? "now" : "at"),
                           period_minutes: params[:period_minutes], run_keys: params[:run_keys], route_ids: params[:route_ids])
        render_data find_by(notice.id), NoticeBlueprint, status:
      end

      def find_by(id) = policy_scope(Notice).includes(*INCLUDES).find(id)
    end
  end
end
