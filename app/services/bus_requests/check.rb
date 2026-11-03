# The service check of a request (Convoy OS rfCk): Route Fit for each session it asks for, on the routes running from
# its start date. A renewal whose child already rides is Covered on its current route; an accepted request shows the
# seat held. Worst session wins: Fits, New Stop, Not Checked, Bus Full, New Area. One instance per page (routes cached).
module BusRequests
  class Check
    OPEN = [ "Requested", "Under Review", "Waitlisted", "Lapsed" ].freeze
    OPEN_CHANGE = BusRequests::OPEN

    def initialize(school, today: Date.current)
      @routes = RouteFit::Routes.new(school)
      @today = today
    end

    def call(req)
      return unless %w[new adr].include?(req.kind)

      st = req.live_status
      return if req.kind == "adr" && !OPEN_CHANGE.include?(st)
      return held(req) if %w[Accepted Active].include?(st) && req.places.any?
      return unless OPEN.include?(st) || req.kind == "adr"

      date = [ req.kind == "adr" ? req.effective_on : req.start_on, @today ].compact.max
      if req.renew && req.school_rider && (cur = current(req.school_rider.rid, date))
        return { code: "covered", kind: "current", label: "Covered", tone: "success", current: true, summary: "#{cur} | current route", sessions: {} }
      end

      fits = sessions(req, date)
      return if fits.empty?

      kinds = fits.values.map { it[:kind] }.reject { it == "none" }
      worst = (kinds.presence || [ "none" ]).max_by { RouteFit::RANK[it] }
      label, tone, code = RouteFit::KINDS[worst]
      { code:, kind: worst, label: label + (fits.values.any? { it[:kind] == "none" } ? " (part)" : ""), tone:, current: false,
        free: fits.values.filter_map { it[:free] }.min, summary: fits.map { |s, f| "#{s} #{one(s, f)}" }.join(" | "), sessions: fits }
    end

    # Where the child goes on accepting: route and stop per session that fits or takes a new stop.
    def places(req)
      date = [ req.start_on, @today ].compact.max
      sessions(req, date).filter_map do |s, f|
        next unless %w[fits new].include?(f[:kind])

        { session: s, school_route_id: f[:route], route_label: f[:label], kind: f[:kind], stop_name: f[:stop], delta_minutes: f[:delta] || 0 }
      end
    end

    # A seat free beyond the buffer (or the child's current route).
    def seat?(check, buffer)
      check && check[:code] == "covered" && (check[:current] || check[:free].to_i > buffer.to_i)
    end

    private

    def sessions(req, date)
      ll = req.lat && [ req.lat.to_f, req.lng.to_f ]
      { "AM" => req.am, "PM" => req.pm }.select { _2 }.keys.to_h do |s|
        rt = @routes.for(s, date)
        f = rt ? RouteFit.fit(session: s, home: { ll:, postal: req.postal }, school: rt[:school], p: rt[:p], routes: rt[:routes]) : nil
        [ s, f ? f.except(:x).merge(tm: f[:tm] && Clock.hm(f[:tm].round)) : { kind: "none", impact: [ "No #{s} route plan yet, so this session is not checked" ] } ]
      end
    end

    def one(session, f)
      txt = f[:kind] == "none" ? "Not checked: no #{session} route plan yet" : RouteFit::KINDS[f[:kind]][0]
      txt += " on #{f[:label]}" if f[:label]
      txt += " (+#{[ 1, f[:delta].round ].max} min)" if f[:kind] == "new"
      txt += ": #{f[:routes].join(', ')}" if f[:kind] == "full" && f[:routes]
      txt
    end

    def current(rid, date)
      rt = @routes.for("AM", date) || @routes.for("PM", date)
      rt && rt[:plan].routes.find { |r| r.riders.any? { it.rid == rid } }&.label
    end

    def held(req)
      { code: "covered", kind: "held", label: "Seat held", tone: "success", current: false,
        summary: req.places.map { "#{it.session} #{it.route_label}, #{it.stop_name}" }.join(" | "), sessions: {} }
    end
  end
end
