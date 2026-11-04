# Live Map board: every bus (own and operator) with its state, last position, device, driver and the run it is on (point
# reached, next point and ETA), or its next / last run today. `detail` adds the device's health and the run's stops.
module LiveMap
  class Board
    STATES = %w[on_trip available offline].freeze

    def initialize(vehicles, now: Time.current)
      @vehicles = vehicles.to_a
      @now = now
      @runs = LiveMap.runs_around(@vehicles.map(&:id), now).group_by(&:vehicle_id)
    end

    def rows = @vehicles.map { |v| row(v) }

    def detail(vehicle)
      r = row(vehicle)
      lp = vehicle.live_position
      device = lp&.tracking_device || vehicle.tracking_devices.min_by(&:id)
      r[:device] = device && {
        id: device.id, kind: device.kind, name: device.name, sharing_enabled: device.sharing_enabled,
        report_interval_seconds: device.report_interval_seconds,
        battery_pct: lp&.battery_pct, gps_signal: r[:online] ? lp&.gps_signal : "none", gsm_bars: r[:online] ? lp&.gsm_bars : 0
      }
      occ = run_of(vehicle)
      r[:run] = r[:run].merge(run_detail(occ, lp)) if occ
      r
    end

    private

    def row(v)
      lp = v.live_position
      online = lp.present? && lp.recorded_at > @now - OFFLINE_AFTER
      runs = (@runs[v.id] || []).select { |o| o.date == @now.to_date || o.ends_at > @now.beginning_of_day }
      occ = LiveMap.run_now(runs, @now)
      state = if occ then "on_trip" elsif online then "available" else "offline" end
      {
        id: v.id, plate: v.plate, make: v.make, model: v.model, seats: v.seats, ownership: v.ownership, operator: v.operator&.name,
        team: v.vehicle_team&.slice(:id, :name, :color), driver: driver(v, occ),
        state:, online:, on_map: lp.present?,
        position: lp && { lat: lp.lat, lng: lp.lng, speed_kmh: online ? lp.speed_kmh&.round : 0, heading: lp.heading, recorded_at: lp.recorded_at },
        last_reported_at: lp&.recorded_at, road: nil,
        device: (lp&.tracking_device || v.tracking_devices.min_by(&:id))&.slice(:kind, :name),
        run: occ && run_row(occ, lp),
        next_run: (n = runs.find { |o| o != occ && o.starts_at > @now }) && brief(n).merge(starts_at: n.starts_at),
        last_run: occ ? nil : (l = runs.reverse.find { |o| (o.ended_at || o.ends_at) <= @now }) && brief(l).merge(ended_at: l.ended_at || l.ends_at)
      }
    end

    def run_of(v) = LiveMap.run_now(@runs[v.id] || [], @now)

    def driver(v, occ)
      info = occ&.decorate&.driver_info
      return info.slice(:name, :phone) if info

      d = v.default_driver_on(@now.to_date)
      d ? { name: d.name, phone: d.phone } : (v.driver_name.presence && { name: v.driver_name, phone: v.driver_phone })
    end

    def brief(o)
      { id: o.id, trip_label: o.trip_label, title: o.decorate.title, client: o.client&.name, school: o.school_route&.plan&.school&.name }
    end

    # The run on the board: where the bus is in it (points reached, the next point, ETA there or the time it arrived).
    def run_row(occ, lp)
      stops = stops_of(occ)
      k = stops.index { |s| !s[:left] } || (stops.size - 1)
      nxt = stops[k]
      at_stop = nxt && nxt[:arrived_at].present? && !nxt[:left]
      eta = nxt && !at_stop ? eta_at(nxt, lp) : nil
      brief(occ).merge(
        date: occ.date, key: occ.decorate.key, kind: occ.kind, kind_name: occ.school_route_id ? "School Route" : Trip::KIND_NAMES[occ.kind],
        trip_id: occ.trip_id, school_route_id: occ.school_route_id, starts_at: occ.starts_at, ends_at: occ.ends_at,
        points: stops.size, points_done: stops.count { |s| s[:reached] },
        next_stop: nxt && { position: nxt[:position], number: k + 1, last: k == stops.size - 1, name: nxt[:name], planned_at: nxt[:planned_at],
                            at_stop: !!at_stop, arrived_at: at_stop ? nxt[:arrived_at] : nil, eta_at: eta,
                            late_minutes: late(nxt, at_stop ? nxt[:arrived_at] : eta) }
      )
    end

    # Drawer: every stop (done / current / upcoming, planned and actual times, students of a School Run), On Board, ETA Last.
    def run_detail(occ, lp)
      stops = stops_of(occ)
      k = stops.index { |s| !s[:left] }
      cur = k && stops[k]
      at = cur && (cur[:arrived_at] || eta_at(cur, lp))
      delay = at && cur[:planned_at] ? at - cur[:planned_at] : 0
      kids = students(occ)
      events = occ.stop_events
      {
        on_board: [ events.sum { |e| e.boarded.to_i } - events.sum { |e| e.alighted.to_i }, 0 ].max,
        eta_last: stops.last && (stops.last[:arrived_at] || (stops.last[:planned_at] && [ stops.last[:planned_at] + [ delay, 0 ].max, @now ].max)),
        stops: stops.each_with_index.map do |s, i|
          s.except(:reached, :left).merge(state: s[:reached] ? "done" : (i == k ? "current" : "upcoming"), students: kids[s[:name]] || [])
        end
      }
    end

    def stops_of(occ)
      @stops ||= {}
      @stops[occ.id] ||= begin
        events = occ.stop_events.index_by(&:position)
        list = Occurrences::Stops.planned(occ)
        list.each_with_index.map do |s, i|
          e = events[s[:position]]
          reached = e.present? && (e.skipped || e.arrived_at.present?)
          { position: s[:position], name: s[:name], use: s[:use], lat: s[:lat]&.to_f, lng: s[:lng]&.to_f,
            planned_at: LiveMap.at_minute(occ, s[:planned_minute]), arrived_at: e&.arrived_at, departed_at: e&.departed_at,
            skipped: e&.skipped || false, reached:, left: reached && (e.skipped || e.departed_at.present? || i == list.size - 1) }
        end
      end
    end

    def eta_at(stop, lp)
      return stop[:planned_at] unless lp && stop[:lat] && lp.recorded_at > @now - OFFLINE_AFTER

      @now + LiveMap.eta_minutes([ lp.lat, lp.lng ], [ stop[:lat], stop[:lng] ]).minutes
    end

    def late(stop, at)
      return nil unless stop[:planned_at] && at

      [ ((at - stop[:planned_at]) / 60).round, 0 ].max
    end

    # School Live statuses in the School Run words of the drawer.
    SCHOOL_STATUS = { "waiting" => "expected", "on_board" => "boarded", "at_school" => "alighted", "dropped_off" => "alighted",
                      "no_show" => "not_boarded", "not_required" => "not_boarding" }.freeze

    # The students of each stop (by stop name) with Boarded / Alighted / Absent so far: a School Run's, or a School Bus
    # route's riders (level, home address) from Live Ops.
    def students(occ)
      return school_bus_students(occ) if occ.school_route_id
      return {} unless occ.trip&.school_run?

      SchoolRuns::Passengers.call(occ)[:stops].to_h do |s|
        [ s[:name], s[:students].map { |st| st.slice(:key, :name, :class_name, :status, :boarded_at, :alighted_at) } ]
      end
    end

    def school_bus_students(occ)
      ActiveRecord::Associations::Preloader.new(records: [ occ ], associations: [ :passenger_marks, { school_route: { stops: :riders } } ]).call
      school = occ.school_route.plan.school
      ctx = SchoolLive.context(school, occ.date, [ occ ])
      run = SchoolLive::Run.new(occ, school:, now: @now, **ctx)
      run.riders.group_by { it[:stop][:name] }.transform_values do |list|
        list.map do |r|
          { key: r[:rid], name: r[:name], class_name: r[:level], address: ctx[:names][r[:rid]]&.address, status: SCHOOL_STATUS[r[:status]],
            boarded_at: r[:boarded_at], alighted_at: r[:alighted_at] }
        end
      end
    end
  end
end
