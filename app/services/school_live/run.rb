# One School Bus run at a time (port of School Live Ops core + stu): its points (the route's stops, and the school last
# for the morning or first for the afternoon), what was recorded at them, lateness against plan (at the last stop
# reached, or the straight-line ETA to the next one), the school ETA, GPS lost, the status label, and each child on it:
# Bus Not Required (parent, or marked not boarding today), Waiting, On Board, At School / Dropped Off, No Show.
module SchoolLive
  class Run
    STATUSES = %w[waiting on_board at_school dropped_off not_required no_show].freeze

    attr_reader :occ, :route, :stops, :riders

    def initialize(occ, school:, names:, absences:, now: Time.current)
      @occ = occ
      @route = occ.school_route
      @school = school
      @now = now
      @am = route.plan.session == "am"
      @live = occ.vehicle&.live_position
      events = occ.stop_events.index_by(&:position)
      list = route.stops.to_a
      @stops = list.each_with_index.map do |s, i|
        e = events[i]
        reached = e.present? && (e.skipped || e.arrived_at.present?)
        { index: i, name: s.name, lat: s.lat&.to_f, lng: s.lng&.to_f, planned_at: LiveMap.at_minute(occ, s.scheduled_time),
          arrived_at: e&.arrived_at, departed_at: e&.departed_at, skipped: e&.skipped || false, reached:,
          left: reached && (e.skipped || e.departed_at.present? || (!@am && i == list.size - 1)) }
      end
      boardings = occ.passenger_marks.index_by(&:passenger_key)
      @riders = list.each_with_index.flat_map do |s, i|
        s.riders.sort_by(&:rid).map { |r| rider(r.rid, i, names[r.rid], absences[r.rid], boardings[r.rid]) }
      end
    end

    def am? = @am
    def done? = occ.ended_at.present? || occ.completed?
    def started? = done? || occ.started_at.present? || stops.any? { it[:reached] }
    def running? = started? && !done?
    def gps_lost? = running? && (@live.nil? || @live.recorded_at < @now - OpsControl::GPS[0].minutes)

    # Planned and actual time at the school: arrival in the morning, departure in the afternoon.
    def school_planned_at = @am ? occ.ends_at : occ.starts_at
    def school_at = @am ? occ.ended_at : occ.started_at

    # Points: the stops plus the school; done = left (the school once arrived, or once left in the afternoon).
    def points = stops.size + 1
    def points_done = done? ? points : stops.count { it[:left] } + (!@am && started? ? 1 : 0)

    def next_stop = done? ? nil : stops.find { !it[:left] }
    def at_stop = stops.find { it[:reached] && !it[:left] }

    # Minutes late now: at the school when done, at the last stop reached, or the ETA to the next stop.
    def late_minutes
      @late_minutes ||= begin
        mins = []
        mins << minutes(school_at - school_planned_at) if done? && school_at
        last = stops.select { it[:arrived_at] && it[:planned_at] }.last
        mins << minutes(last[:arrived_at] - last[:planned_at]) if last
        if running? && !gps_lost? && (n = next_stop) && !n[:reached] && n[:planned_at] && n[:lat]
          mins << minutes(eta_to(n) - n[:planned_at])
        end
        [ (done? ? mins.first : mins.max).to_i, 0 ].max
      end
    end

    # When the run ends: at the school in the morning, the last drop-off in the afternoon.
    def end_planned_at = @am ? occ.ends_at : (stops.last&.dig(:planned_at) || occ.ends_at)

    def end_at
      return (@am ? occ.ended_at : stops.last&.dig(:arrived_at)) || occ.ended_at || occ.ends_at if done?

      end_planned_at + late_minutes.minutes
    end

    # Expected at a stop not reached yet.
    def expected_at(stop) = stop[:planned_at] && (stop[:planned_at] + late_minutes.minutes)

    def status
      return { key: "arrived", label: @am ? "Arrived" : "Completed", tone: "success", at: end_at } if done?
      return { key: "not_started", label: "Not started", tone: "neutral" } unless started?
      return { key: "gps_lost", label: "GPS lost", tone: "danger" } if gps_lost?
      return { key: "late", label: "Late #{late_minutes} min", tone: "danger" } if late_minutes >= LATE[1]
      return { key: "late", label: "Late #{late_minutes} min", tone: "warning" } if late_minutes >= LATE[0]

      { key: "on_time", label: "On time", tone: "success" }
    end

    def counts
      @counts ||= STATUSES.index_with { |k| riders.count { it[:status] == k } }.merge(total: riders.size)
    end

    def position
      @live && { lat: @live.lat, lng: @live.lng, speed_kmh: @live.speed_kmh&.round, heading: @live.heading, recorded_at: @live.recorded_at }
    end

    def school_point = { name: @school.name, lat: @school.lat&.to_f, lng: @school.lng&.to_f }

    private

    def rider(rid, i, info, absence, b)
      stop = stops[i]
      status, by = if b.nil? && absence&.covers?(route.plan.session) then [ "not_required", "Parent" ]
      elsif b.nil? then [ "waiting", nil ]
      elsif b.state == "not_boarding" then [ "not_required", b.marked_by ]
      elsif b.state == "not_boarded" then [ "no_show", b.marked_by ]
      elsif b.state == "alighted" then [ @am ? "at_school" : "dropped_off", b.marked_by ]
      else [ "on_board", b.marked_by ]
      end
      board = b&.board_lat && { lat: b.board_lat, lng: b.board_lng,
                                distance_m: (stop[:lat] && Geo.metres([ b.board_lat, b.board_lng ], [ stop[:lat], stop[:lng] ]).round) }
      { rid:, name: info&.name || rid, level: info&.grade, stop: { index: i, name: stop[:name] }, status:, marked_by: by,
        reason: absence ? absence.reason_text : nil, boarded_at: b&.boarded_at, board_method: b&.board_method, board:,
        alighted_at: b&.alighted_at, alight_method: b&.alight_method }
    end

    def eta_to(stop) = @now + LiveMap.eta_minutes([ @live.lat, @live.lng ], [ stop[:lat], stop[:lng] ]).minutes
    def minutes(seconds) = (seconds / 60.0).round
  end
end
