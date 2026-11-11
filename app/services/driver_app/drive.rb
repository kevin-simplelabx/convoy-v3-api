# Driving a run in the Convoy Driver app, in the app's own words:
#   start       Swipe to start (On the Way): from 60 minutes before the start, one trip on the road at a time
#   arrive      at a point (by hand or after the geofence countdown)
#   leave       a point: attendance or the count first when the route asks for it (force = leave anyway, recorded as left
#               early with the children still missing); passengers on the bus after it
#   skip_stop   a point (a reason; auto = nobody riding today)
#   attendance  tick children Boarded / Not Boarded / Alighted (QR scan or by hand)
#   count       boarded and alighted at the current point (runs without names)
#   route       Edit Route: the points skipped today and the children not boarding (the whole set each time)
#   complete    at the last point: everyone on board alights, optional feedback, the run ends
#   force_end   end where it is (a reason, after calling operations): the rest is not reached, who is on board is recorded
#   skip        skip the whole trip before leaving the first point (a reason)
#   disposal_*  a disposal's start, runs, extensions and end (DisposalActions)
# Each action carries client_id (uuid, from the app) and at (when it happened on the phone): the same client_id again
# does nothing (offline retries). Only this service writes driving data on a run.
module DriverApp
  class Drive < ApplicationService
    include DisposalActions

    ACTIONS = DriverAppAction::KINDS
    FORCE_END_REASONS = [ "Vehicle breakdown", "Accident", "Road closed", "Medical emergency", "Instructed by operations", "Other" ].freeze
    SKIP_TRIP_REASONS = [ "Traffic Congestion", "Permission granted by Supervisor/Manager" ].freeze
    SKIP_STOP_REASONS = [ "No Passengers", "Passengers are late", "Traffic Congestion", "Instruction given by supervisor/client" ].freeze
    START_EARLY = 60.minutes
    # Actions that record arrivals at points: On Time (Trip History, Dashboard) is worked out again after them.
    TIMED = %w[arrive leave skip_stop route complete force_end disposal_start disposal_end].freeze
    UUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

    def initialize(account:, member:, occ:, action:, params:)
      @account = account
      @member = member
      @occ = occ
      @action = action.to_s
      @params = params.to_h.deep_symbolize_keys
    end

    # [occurrence, replayed]
    def call
      raise Error, "Unknown action" unless ACTIONS.include?(@action)

      client_id = @params[:client_id].to_s.downcase
      raise Error.new("Send a client_id (UUID) with every action", details: { client_id: [ "must be a UUID" ] }) unless client_id.match?(UUID)
      return [ @occ, true ] if DriverAppAction.exists?(driver_account_id: @account.id, client_id:)

      TripOccurrence.transaction do
        @occ.lock!
        @at = at
        check_run!
        public_send(@action)
        TripHistory::Punctuality.call(@occ) if TIMED.include?(@action)
        DriverAppAction.create!(company_id: @occ.company_id, driver_account: @account, client_id:, occurrence: @occ, kind: @action, at: @at,
                                payload:)
      end
      [ @occ, false ]
    end

    def start
      raise Error.new("This trip has started", code: "started") if @occ.started_at
      if @at < @occ.starts_at - START_EARLY
        raise Error.new("You can start this trip from #{Clock.hm(@occ.start_time - 60)}", code: "too_early")
      end
      busy = Runs.on_the_road(@member, on: @occ.date)
      busy = nil if busy&.id == @occ.id
      raise Error.new("Finish the trip you are on first", code: "busy", details: { run_id: busy.id }) if busy

      Occurrences::DriverProgress.call(@occ, :start, at: @at)
      @occ.update_columns(driver_seen_at: @occ.driver_seen_at || @at) # rubocop:disable Rails/SkipsModelValidations
    end

    def arrive
      point = point!
      raise Error, "#{point[:name]} is a waypoint: drive through it" if point[:waypoint]

      event = event_for(point)
      event.update!(arrived_at: event.arrived_at || @at, skipped: false, skip_reason: nil, skipped_by: nil, source: "driver_app")
    end

    def leave
      point = point!
      event = event_for(point)
      raise Error.new("Arrive at #{point[:name]} first", code: "not_arrived") unless event.arrived_at
      raise Error.new("Start the disposal with the odometer", code: "disposal_not_started") if @occ.kind == "disposal" && @occ.disposal.nil?

      missing = missing_at(point)
      if missing.any? && !force?
        raise Error.new("Take attendance at #{point[:name]} first", code: "attendance_needed",
                        details: { missing: missing.size, names: missing.pluck(:name) })
      end
      boarded, alighted = counts_at(point, event)
      if Runs.requires(@occ) == "count" && boarded.nil? && alighted.nil? && !force?
        raise Error.new("Count the passengers at #{point[:name]} first", code: "count_needed")
      end

      event.update!(departed_at: @at, boarded:, alighted:, on_board: on_board_after(point, boarded, alighted),
                    left_early_missing: missing.any? ? missing.size : nil, source: "driver_app")
    end

    def skip_stop
      point = point!
      reason = @params[:reason].to_s.squish.presence || (@params[:auto] ? "No one boarding today" : nil)
      raise Error.new("Pick a reason", details: { reason: [ "can't be blank" ] }) unless reason

      event = event_for(point)
      raise Error, "#{point[:name]} was already reached" if event.departed_at

      event.update!(skipped: true, skip_reason: reason, skipped_by: @params[:auto] ? "auto" : "driver", on_board: on_board_after(point, 0, 0),
                    source: "driver_app")
    end

    def attendance
      marks = Array(@params[:marks]).map do |m|
        { key: m[:id], state: m[:state], method: m[:method], lat: m[:lat], lng: m[:lng], at: @at }
      end
      raise Error, "Send the children's marks" if marks.empty?

      Occurrences::MarkPassengers.call(occ: @occ, marks:, by: driver_name, source: "driver_app")
    end

    def count
      point = point!
      boarded = count_param(:boarded)
      alighted = count_param(:alighted)
      event = event_for(point)
      event.update!(boarded:, alighted:, source: "driver_app")
    end

    # Edit Route: params skip (positions) and not_boarding (children), each the whole set.
    def route
      raise Error, "This trip has ended" if @occ.ended_at

      points = self.points
      skip = Array(@params[:skip]).map(&:to_i)
      bad = skip - points.reject { it[:waypoint] }.map { it[:position] }
      raise Error, "Unknown point #{bad.first}" if bad.any?

      @occ.stop_events.select(&:planned_skip).each do |e|
        e.update!(planned_skip: false, skipped: false, skip_reason: nil, skipped_by: nil) unless skip.include?(e.position) || e.departed_at
      end
      points.select { skip.include?(it[:position]) }.each do |p|
        e = event_for(p)
        next if e.arrived_at

        e.update!(planned_skip: true, skipped: true, skip_reason: "Skipped by the driver before the trip", skipped_by: "plan", source: "driver_app")
      end

      wanted = Array(@params[:not_boarding]).map(&:to_s)
      now = @occ.passenger_marks.select { it.state == "not_boarding" }.map(&:passenger_key)
      marks = (wanted - now).map { { key: it, state: "not_boarding", at: @at } } + (now - wanted).map { { key: it, state: "expected" } }
      Occurrences::MarkPassengers.call(occ: @occ, marks:, by: driver_name, source: "driver_app") if marks.any?
    end

    def complete
      started!
      raise Error.new("End the disposal with the odometer", code: "disposal_end_needed") if @occ.kind == "disposal"
      last = points.reject { it[:waypoint] }.last
      event = event_for(last)
      on_board = on_board_before(last)
      on_names = @occ.passenger_marks.select { it.state == "boarded" }
      if on_names.any?
        Occurrences::MarkPassengers.call(occ: @occ, marks: on_names.map { { key: it.passenger_key, state: "alighted", at: @at } }, by: driver_name, source: "driver_app")
      end
      event.update!(arrived_at: event.arrived_at || @at, departed_at: event.departed_at || @at, skipped: false,
                    alighted: event.alighted || on_board, on_board: 0, source: "driver_app")
      feedback(@params[:feedback])
      Occurrences::DriverProgress.call(@occ, :end, at: @at)
      @occ.update_columns(driver_end: "completed", end_on_board: 0) # rubocop:disable Rails/SkipsModelValidations
    end

    def force_end
      started!
      reason = @params[:reason].to_s
      raise Error.new("Pick why the trip ends here", details: { reason: [ "is not on the list" ] }) unless FORCE_END_REASONS.include?(reason)
      raise Error.new("Call operations first, then confirm", code: "call_operations") unless ActiveModel::Type::Boolean.new.cast(@params[:called_operations])

      on_board = current_on_board
      points.reject { it[:waypoint] }.each do |p|
        e = event_for(p)
        next if e.departed_at || e.skipped

        if e.arrived_at then e.update!(departed_at: @at, on_board:, source: "driver_app")
        else e.update!(skipped: true, skip_reason: "Trip force ended", skipped_by: "driver", on_board:, source: "driver_app")
        end
      end
      feedback(@params[:feedback] || "Force ended: #{reason}")
      @occ.update_columns(ended_at: @at, status: "completed", overridden_fields: @occ.overridden_fields | [ "status" ], # rubocop:disable Rails/SkipsModelValidations
                          driver_end: "forced", driver_end_reason: reason, end_on_board: on_board, updated_at: Time.current, **next_version)
    end

    def skip
      reason = @params[:reason].to_s
      raise Error.new("Pick a reason", details: { reason: [ "is not on the list" ] }) unless SKIP_TRIP_REASONS.include?(reason)
      raise Error.new("This trip has started. Use Force End Trip", code: "started") if @occ.stop_events.any?(&:departed_at)

      @occ.update_columns(status: "cancelled", cancelled_at: @at, cancelled_by_id: nil, cancelled_by_client: false, # rubocop:disable Rails/SkipsModelValidations
                          overridden_fields: @occ.overridden_fields | [ "status" ], ended_at: @occ.started_at && @at,
                          driver_end: "skipped", driver_end_reason: reason, updated_at: Time.current, **next_version)
    end

    private

    # A new status is a real change: an office drawer opened before it gets 409 on its next action. The row is held by
    # lock! (call), so its lock_version is current.
    def next_version = { lock_version: @occ.lock_version + 1 }

    # What was sent, for the log: files as their names.
    def payload
      @params.except(:client_id).deep_transform_values { it.respond_to?(:original_filename) ? "file:#{it.original_filename}" : it }
    end

    def at
      given = @params[:at].presence && Time.zone.iso8601(@params[:at].to_s)
      [ given || Time.current, Time.current ].min
    rescue ArgumentError
      raise Error.new("at must be an ISO 8601 time", details: { at: [ "is not a time" ] })
    end

    def check_run!
      raise Error.new("This trip was given to another driver", code: "replaced") unless Runs.mine?(@occ, @member)
      raise Error.new("This trip was cancelled", code: "cancelled") if @occ.cancelled?
      raise Error.new("This trip has ended", code: "ended") if @occ.ended_at && @action != "attendance"
    end

    def started!
      raise Error.new("Swipe to start the trip first", code: "not_started") unless @occ.started_at
    end

    def force? = ActiveModel::Type::Boolean.new.cast(@params[:force])

    def points = @points ||= Occurrences::Stops.detailed(@occ)

    def point!
      started! unless @action == "count"
      position = @params[:position]
      found = position.present? && points.find { it[:position] == position.to_i }
      found || raise(Error.new("Unknown point #{position}", details: { position: [ "is not a point of this trip" ] }))
    end

    def event_for(point) = Runs.event_for(@occ, point)

    def passengers = @passengers ||= Occurrences::Passengers.call(@occ.tap { it.passenger_marks.reset }, points:)

    # Children who should get on or off here and are not ticked yet.
    def missing_at(point)
      return [] unless Runs.requires(@occ) == "attendance"

      passengers.select do |p|
        (p[:pickup_position] == point[:position] && p[:state] == "expected") ||
          (p[:dropoff_position] == point[:position] && p[:state] == "boarded" && !point[:school])
      end
    end

    # [boarded, alighted] at the point: from the names ticked (attendance runs), else what the app sent or counted before.
    def counts_at(point, event)
      if Runs.requires(@occ) == "attendance"
        on = passengers.count { it[:pickup_position] == point[:position] && it[:state].in?(%w[boarded alighted]) }
        off = passengers.count { it[:dropoff_position] == point[:position] && it[:state] == "alighted" }
        [ on, off ]
      else
        [ @params.key?(:boarded) ? count_param(:boarded) : event.boarded, @params.key?(:alighted) ? count_param(:alighted) : event.alighted ]
      end
    end

    def count_param(key)
      value = Integer(@params[key].presence || 0, exception: false)
      raise Error.new("#{key.to_s.humanize} must be 0 or more", details: { key => [ "must be 0 or more" ] }) if value.nil? || value.negative?

      value
    end

    # Passengers on the bus before reaching the point: what was left after the points before it.
    def on_board_before(point)
      before = points.take_while { it[:position] != point[:position] }.map { it[:position] }
      @occ.stop_events.select { before.include?(it.position) && it.on_board }.max_by { before.index(it.position) }&.on_board.to_i
    end

    def on_board_after(point, boarded, alighted)
      given = @params[:on_board].presence && Integer(@params[:on_board], exception: false)
      given || [ on_board_before(point) + boarded.to_i - alighted.to_i, 0 ].max
    end

    # Passengers on the bus now: after the last point recorded, in driving order.
    def current_on_board
      order = points.map { it[:position] }
      @occ.stop_events.select(&:on_board).max_by { |e| order.index(e.position) || -1 }&.on_board.to_i
    end

    def feedback(note)
      return if note.blank?

      report = @occ.driver_report || @occ.build_driver_report(company_id: @occ.company_id)
      report.update!(driver_name:, note: note.to_s.strip.truncate(2000), submitted_at: @at)
    end

    def driver_name = @account.name.presence || @member.name
  end
end
