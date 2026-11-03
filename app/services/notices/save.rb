# Create or edit a notice (Send Notice from the trip drawer, prefilled with the trip and its timing).
# start: "now" or a time; the end is a period (5..30 min or any) or a time. Push and SMS sends are recorded.
module Notices
  class Save < ApplicationService
    def initialize(notice:, attributes:, user:, start: "now", period_minutes: nil, run_keys: nil, route_ids: nil)
      @route_ids = route_ids
      @notice = notice
      @attrs = attributes
      @user = user
      @start = start
      @period = period_minutes.presence&.to_i
      @run_keys = run_keys
    end

    def call
      raise Error, "WhatsApp is not available yet" if @attrs.delete(:whatsapp).present?
      raise Error, "An active or ended notice can't be edited. Duplicate it instead" if @notice.persisted? && @notice.state != "scheduled"

      Notice.transaction do
        @notice.assign_attributes(@attrs)
        @notice.created_by ||= @user
        @notice.starts_at = Time.current if @start.to_s == "now"
        @notice.ends_at = @notice.starts_at + @period.minutes if @period && @notice.starts_at
        @notice.message = @notice.notice_template&.message if @notice.message.blank?
        set_runs
        set_routes
        first = @notice.new_record?
        @notice.save!
        record_sends if first
        @notice
      end
    end

    private

    def set_runs
      return if @run_keys.nil?

      keys = Array(@run_keys).compact_blank
      @notice.all_runs = keys.empty? || keys.include?("all")
      @notice.runs.each(&:mark_for_destruction)
      return if @notice.all_runs? || @notice.trip.nil?

      by_key = @notice.trip.runs.index_by(&:key)
      keys.each { |k| @notice.runs.build(trip_run: by_key.fetch(k) { raise Error, "No timing #{k}" }) }
    end

    # School routes: "all" or the routes picked: the school's, of plans in use while the notice runs
    # (GET /schools/:id/routes?date= lists them).
    def set_routes
      return if @route_ids.nil? || !@notice.for_school?

      ids = Array(@route_ids).compact_blank
      @notice.all_runs = ids.empty? || ids.include?("all")
      @notice.route_targets.each(&:mark_for_destruction)
      return if @notice.all_runs?

      from = (@notice.starts_at || Time.current).to_date
      plans = SchoolPlan.where(school_id: @notice.school_id).running_between(from, [ @notice.ends_at&.to_date, from ].compact.max)
      allowed = SchoolRoute.where(plan: plans, id: ids).pluck(:id)
      raise Error, "Pick routes in use at this school" if allowed.size != ids.uniq.size

      allowed.each { |id| @notice.route_targets.build(school_route_id: id) }
    end

    def record_sends
      %w[push sms].each { |ch| @notice.deliveries.create!(channel: ch) if @notice.public_send(:"#{ch}?") }
    end
  end
end
