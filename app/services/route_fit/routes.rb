# The running routes Route Fit checks a request against (Convoy OS rfRoutes): the session's route plan in use on the
# date (else the latest), each route's stops with times and the postal codes riding from them, and its free seats —
# seats less riders, less seats held for accepted requests not in the plan yet, plus riders gone by then. The arrival
# window and max journey come from the year's Bus Sessions, else the plan's own settings.
module RouteFit
  class Routes
    def initialize(school)
      @school = school
      @cache = {}
    end

    # { plan:, routes:, school: [lat, lng], p: } or nil when the session has no route plan.
    def for(session, date) = @cache.fetch([ session, date ]) { @cache[[ session, date ]] = build(session, date) }

    private

    def plans(session)
      @plans ||= {}
      @plans[session] ||= @school.plans.where(session: session.downcase).includes(routes: { stops: :riders }).to_a.select { it.routes.any? }
    end

    def riders = @riders ||= SchoolRider.where(school: @school).pluck(:rid, :postal, :ends_on).to_h { [ it[0], it[1..] ] }

    def holds
      @holds ||= BusRequestPlace.joins(:bus_request).where(bus_requests: { school_id: @school.id, status: %w[Accepted Active] })
                                .includes(bus_request: [ :school_rider, { first_bill: :payments } ]).to_a
                                .select { %w[Accepted Active].include?(it.bus_request.live_status) }
    end

    def years = @years ||= @school.academic_years.includes(:bus_sessions).to_a

    def build(session, date)
      list = plans(session)
      plan = list.find { it.in_use && it.effective_from <= date && (it.effective_to.nil? || it.effective_to >= date) } || list.max_by(&:id)
      return unless plan && @school.lat

      in_plan = plan.routes.flat_map { |r| r.riders.map(&:rid) }.to_set
      held = holds.select { it.session == session && !in_plan.include?(it.bus_request.school_rider&.rid) }.group_by(&:school_route_id)
      routes = plan.routes.reject(&:hidden).filter_map do |r|
        stops = r.stops.select { it.riders.any? && it.scheduled_time && it.lat }
        next if stops.empty?

        gone = stops.sum { |s| s.riders.count { (e = riders.dig(it.rid, 1)) && e < date } }
        load = r.stops.sum { it.riders.size }
        { id: r.id, label: r.label, free: (r.student_seats || r.seats || r.capacity).to_i - load - held.fetch(r.id, []).size + gone,
          start: r.start_time, end: r.end_time,
          stops: stops.map do |s|
            { name: s.name, ll: [ s.lat.to_f, s.lng.to_f ], tm: s.scheduled_time, n: s.riders.size,
              postals: s.riders.filter_map { riders.dig(it.rid, 0)&.gsub(/\D/, "") }.uniq }
          end }
      end
      { plan:, routes:, school: [ @school.lat.to_f, @school.lng.to_f ], p: limits(plan, session, date) }
    end

    def limits(plan, session, date)
      am = session == "AM"
      year = years.find { it.starts_on <= date && date <= it.ends_on }
      bs = year&.bus_sessions&.find { !it.cca && it.direction == (am ? "to_school" : "to_home") }
      params = plan.params || {}
      win = Array(params[am ? "amWin" : "pmWin"]).map { it.to_s.match?(/\A\d{1,2}:\d{2}\z/) ? Clock.minutes(it.to_s) : nil }
      { arr_from: am ? bs&.arrive_from || win[0] : nil, arr_to: am ? bs&.arrive_to || win[1] : nil,
        hard_cap: bs&.max_journey_minutes || params["hardCap"], base_dwell: params["baseDwell"], per_student: params["perStudent"] }
    end
  end
end
