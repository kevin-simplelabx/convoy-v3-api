# One School Bus run on Live Ops (port of School Live Ops' route view): the bus, alert (GPS lost / late), KPIs (points,
# children on board or at school, school ETA), how children boarded (manual tick, QR, card, palm), the crew (driver,
# bus attendant), the log of what happened so far (newest first) and each stop with its children.
module SchoolLive
  class Detail
    def initialize(run, now:)
      @r = run
      @now = now
    end

    def call
      r = @r
      occ = r.occ
      v = occ.vehicle
      type = SchoolBus::BUS_TYPES[r.route.bus_type]
      boarded = r.riders.select { it[:boarded_at] }
      { occurrence_id: occ.id, route_id: r.route.id, label: r.route.label, session: r.route.plan.session, date: occ.date,
        bus: { plate: v&.plate, type: type&.dig(:label) || r.route.bus_type, seats: r.route.seats || v&.seats, operator: v && (v.operator&.name || "Own fleet") },
        status: r.status, alert: alert, late_minutes: r.late_minutes, points: r.points, points_done: r.points_done, counts: r.counts,
        on_board: r.counts["on_board"], stops_count: r.stops.size,
        next_stop: (n = r.next_stop) && { index: n[:index], name: n[:name], at_stop: r.at_stop&.dig(:index) == n[:index], expected_at: r.expected_at(n) },
        end: { planned_at: r.end_planned_at, at: r.end_at, done: r.done? },
        methods: OccurrencePassenger::METHODS.keys.index_with { |m| boarded.count { it[:board_method] == m } },
        crew: crew, log: log, school: r.school_point, position: r.position,
        stops: r.stops.map { |s| stop(s) } }
    end

    private

    def alert
      r = @r
      return nil unless r.running?
      return { kind: "gps_lost", tone: "danger", title: "GPS signal lost", last_ping: r.position&.dig(:recorded_at) } if r.gps_lost?
      return nil if r.late_minutes < LATE[0]

      { kind: "late", tone: r.late_minutes >= LATE[1] ? "danger" : "warning", title: "Running #{r.late_minutes} min late",
        school_eta: r.end_at, planned_at: r.end_planned_at }
    end

    def crew
      d = @r.occ.decorate.driver_info
      a = @r.route.attendant
      [ d && { role: "Driver", name: d[:name], phone: d[:phone] }, a && { role: "Bus Attendant", name: a.name, phone: a.phone } ].compact
    end

    # What happened so far, newest first: trip started, arrived at each stop, boarded / dropped off there, children not at the
    # stop, children marked by hand, Ops Control alerts on the run, arrived at the school.
    def log
      r = @r
      occ = r.occ
      ev = []
      ev << [ occ.started_at, "started", "Trip started" ] if occ.started_at
      r.stops.each do |s|
        ev << [ s[:arrived_at], "arrived", "Arrived at #{s[:name]}" ] if s[:arrived_at]
        here = r.riders.select { it[:stop][:index] == s[:index] }
        here.select { it[:status] == "no_show" }.each { ev << [ s[:departed_at] || s[:arrived_at], "no_show", "#{it[:name]} not at stop#{". Marked by #{it[:marked_by]}" if it[:marked_by]}" ] }
        here.select { it[:board_method] == "tick" && it[:boarded_at] }.each { ev << [ it[:boarded_at], "manual", "#{it[:name]} marked present manually#{" by #{it[:marked_by]}" if it[:marked_by]}" ] }
        next unless s[:departed_at]

        n = r.am? ? here.count { it[:boarded_at] } : here.count { it[:alighted_at] }
        ev << [ s[:departed_at], r.am? ? "boarded" : "dropped_off", "#{n} #{n == 1 ? 'student' : 'students'} #{r.am? ? 'boarded' : 'dropped off'} at #{s[:name]}" ]
      end
      occ.ops_alerts.each do |a|
        ev << [ a.raised_at, "alert_#{a.kind}", a.message ]
        ev << [ a.cleared_at, "cleared_#{a.kind}", "Cleared: #{a.message}" ] if a.cleared_at
      end
      if r.am? && r.done? && r.school_at
        ev << [ r.school_at, "at_school", "Arrived at #{r.school_point[:name]}. #{r.counts['at_school']} students checked in" ]
      end
      ev.each_with_index.select { |e, _| e[0] && e[0] <= @now }.sort_by { |e, i| [ -e[0].to_f, -i ] }.map { |(at, kind, text), _| { at:, kind:, text: } }
    end

    def stop(s)
      r = @r
      kids = r.riders.select { it[:stop][:index] == s[:index] }
      { index: s[:index], number: s[:index] + 1, name: s[:name], lat: s[:lat], lng: s[:lng], planned_at: s[:planned_at],
        state: s[:left] || r.done? ? "done" : (s[:reached] ? "at" : "todo"), arrived_at: s[:arrived_at], departed_at: s[:departed_at],
        late_minutes: s[:departed_at] && s[:planned_at] ? [ (((s[:arrived_at] || s[:departed_at]) - s[:planned_at]) / 60).round, 0 ].max : nil,
        expected_at: s[:reached] || r.done? ? nil : r.expected_at(s), riders: kids.map { it.except(:stop) } }
    end
  end
end
