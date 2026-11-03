# Live Ops for a school, a day and a session (port of School Live Ops renderVals): the sessions of the day, KPIs (stops
# done with the school counted, buses on the road, children on board / at school / waiting / absent, when the last run
# ends against plan, runs needing attention), what needs attention (GPS lost, late, a child not at the stop), the counts
# of the run filters and a row per run with its route line and bus position for the map. `route(id)` is one run in detail.
module SchoolLive
  class Board
    FILTERS = %w[all road late done].freeze

    def initialize(school, date, session: nil, now: Time.current)
      @school = school
      @date = date
      @now = now
      by = SchoolLive.runs(school, date)
      @sessions = SchoolLive.sessions(by)
      @session = SESSIONS.key?(session) ? session : SchoolLive.default_session(@sessions, now)
      list = by[@session] || []
      ctx = SchoolLive.context(school, date, list)
      @runs = list.map { Run.new(it, school:, now:, **ctx) }
    end

    def call(filter: "all")
      rows = @runs.select { |r| keep?(r, filter) }.map { row(it) }
      { school: { id: @school.id, name: @school.name, lat: @school.lat&.to_f, lng: @school.lng&.to_f }, date: @date, now: @now,
        sessions: @sessions, session: @session, kpis:, attention: attention,
        filters: FILTERS.index_with { |f| @runs.count { keep?(it, f) } }, rows: }
    end

    def route(id) = Detail.new(@runs.find { it.occ.id == id.to_i } || raise(ActiveRecord::RecordNotFound), now: @now).call

    private

    def keep?(r, filter)
      case filter
      when "road" then r.running?
      when "late" then r.running? && (r.gps_lost? || r.late_minutes >= LATE[0])
      when "done" then r.done?
      else true
      end
    end

    def kpis
      c = SchoolLive::Run::STATUSES.index_with { |k| @runs.sum { it.counts[k] } }
      planned = @runs.map(&:end_planned_at).max
      ends = @runs.map(&:end_at).max
      issues = attention
      { points: @runs.sum(&:points), points_done: @runs.sum(&:points_done),
        buses: { on_road: @runs.count(&:running?), arrived: @runs.count(&:done?), not_started: @runs.count { !it.started? }, total: @runs.size },
        riders: c.merge(absent: c["not_required"] + c["no_show"], total: @runs.sum { it.counts[:total] }),
        completion: { at: ends, planned_at: planned, late_minutes: ends && planned ? [ ((ends - planned) / 60).round, 0 ].max : 0 },
        attention: { runs: issues.map { it[:occurrence_id] }.uniq.size, issues: issues.size } }
    end

    # Most severe first: GPS lost / badly late (4), late (3), a child not at the stop (2).
    def attention
      @attention ||= @runs.flat_map do |r|
        items = []
        if r.running?
          if r.gps_lost?
            last = r.stops.select { it[:reached] }.last || r.stops.first
            items << issue(r, 4, "gps_lost", "GPS signal lost", last_ping: r.position&.dig(:recorded_at), near: last&.dig(:name))
          end
          if r.late_minutes >= LATE[0]
            items << issue(r, r.late_minutes >= LATE[1] ? 4 : 3, "late", "Running #{r.late_minutes} min late",
                           late_minutes: r.late_minutes, school_eta: r.end_at, planned_at: r.end_planned_at)
          end
        end
        r.riders.select { it[:status] == "no_show" }.each do |k|
          items << issue(r, 2, "no_show", "Student not at stop", rider: k.slice(:rid, :name), stop: k[:stop][:name], marked_by: k[:marked_by])
        end
        items
      end.sort_by { -it[:severity] }
    end

    def issue(r, severity, kind, title, **details)
      { occurrence_id: r.occ.id, route: r.route.label, severity:, kind:, title:, **details }
    end

    def row(r)
      n = r.next_stop
      at = r.at_stop
      { occurrence_id: r.occ.id, route_id: r.route.id, label: r.route.label, plate: r.occ.vehicle&.plate,
        driver: r.occ.decorate.driver_info&.slice(:name, :phone), status: r.status, late_minutes: r.late_minutes,
        points: r.points, points_done: r.points_done, counts: r.counts,
        next_stop: n && { name: n[:name], at_stop: at.present? && at[:index] == n[:index], expected_at: r.expected_at(n) },
        end_at: r.end_at, end_planned_at: r.end_planned_at, starts_at: r.occ.starts_at,
        line: r.stops.map { [ it[:lat], it[:lng] ] }.then { |l| r.am? ? l + [ school_ll ] : [ school_ll ] + l }.reject { it.include?(nil) },
        position: r.running? ? r.position : nil }
    end

    def school_ll = [ @school.lat&.to_f, @school.lng&.to_f ]
  end
end
