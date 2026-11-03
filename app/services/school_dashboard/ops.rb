# School Dashboard › Operations (port of dashVals' ops half): what today is (school day, special day, holiday, no service),
# today's bus sessions with their routes, buses, riders and seats, what needs attention (setup steps, trips without a
# bus, stop requests), the next 3 months' calendar, the next 90 days' plan and rider changes, and the students
# (on a route or not, AM / PM / CCA, distance from school, levels).
module SchoolDashboard
  class Ops
    SPECIAL = { "early_dismissal" => "Early Dismissal", "late_dismissal" => "Late Dismissal", "early_arrival" => "Early Arrival",
                "late_arrival" => "Late Arrival", "other" => "Special day" }.freeze
    DAYS = %w[Mon Tue Wed Thu Fri Sat Sun].freeze

    def initialize(school, today: Date.current, bin: nil)
      @school = school
      @today = today
      @bin = bin
      @year = SchoolDashboard.year_on(school, today)
    end

    def call
      day = day_type
      list = day[:runs] ? sessions : []
      { date: @today, academic_year: @year&.key, day:, sessions: list, sessions_note: day[:runs] && list.empty? ? sessions_note : nil,
        today: today_stats(day[:runs]), attention:, upcoming:, ahead: Ahead.new(@school, @today, @year).ops,
        students: Students.new(@school, @today, @year, bin: @bin).call }
    end

    private

    def day_type
      return { kind: "no_year", title: "No academic year covers today", runs: false } unless @year

      ph = PublicHoliday.find_by(date: @today)
      hol = @year.holidays.find { it.covers?(@today) }
      term = @year.terms.find { it.covers?(@today) }
      sp = @year.special_days.find { it.date == @today }
      if !@year.operating_days.include?(@today.cwday)
        { kind: "no_service", title: "No service today", detail: "#{DAYS[@today.cwday - 1]} is not an operating day", runs: false }
      elsif ph then { kind: "public_holiday", title: "Public holiday", detail: ph.name, runs: false }
      elsif hol then { kind: "school_holiday", title: "School holiday", detail: hol.name.presence || "Holiday", runs: false }
      elsif !term then { kind: "between_terms", title: "School holidays", detail: "Between terms", runs: false }
      elsif sp
        { kind: "special_day", title: "Special day", runs: true,
          detail: [ "#{SPECIAL[sp.kind]}#{" at #{sp.time_hm}" if sp.time}", sp.description.presence ].compact.join(" | ") }
      else
        { kind: "school_day", title: "School day", detail: "#{@year.period_label} #{term.position}, AY #{@year.key}", runs: true }
      end
    end

    # Today's routes by session (am, pm, asa) from the plans running today.
    def routes
      @routes ||= SchoolRoute.joins(:plan).merge(SchoolDashboard.plans_on(@school, @today))
                             .includes(:plan, :vehicle_changes, :replacements).to_a.group_by { it.plan.session }
    end

    def bus_of(route) = route.replacement_on(@today)&.vehicle_id || route.regular_vehicle_id(@today)

    def sessions
      @year.bus_sessions.select { it.days.include?(@today.cwday) }.map do |s|
        v = s.variants.find { it.days.include?(@today.cwday) }
        t = v || s
        list = routes[s.cca ? "asa" : (s.to_home? ? "pm" : "am")] || []
        riders = list.sum(&:riders_count)
        seats = list.sum { it.student_seats.to_i }
        { name: s.name, direction: s.direction, cca: s.cca, different_today: v.present?,
          arrive_from: (t.arrive_from_hm unless s.to_home?), arrive_to: (t.arrive_to_hm unless s.to_home?),
          depart: (s.to_home? ? (t.depart_hm || t.dismissal_hm) : nil),
          routes: list.size, buses: list.filter_map { bus_of(it) }.uniq.size, riders:, seats:,
          seats_used_pct: seats.positive? ? (riders * 100.0 / seats).round : nil, without_bus: list.count { bus_of(it).nil? } }
      end
    end

    def sessions_note
      return nil unless @year

      @year.bus_sessions.empty? ? "Bus Sessions are not set up for this year" : "No sessions run on #{DAYS[@today.cwday - 1]}"
    end

    def today_stats(runs)
      all = routes.values.flatten
      { routes_running: runs ? all.size : 0, buses_assigned: runs ? all.filter_map { bus_of(it) }.uniq.size : 0, routes: runs ? all.size : 0,
        on_time_pct: nil }
    end

    # Setup steps not done (but the money ones, on Finance), trips without a bus, stops waiting for review.
    def attention
      out = []
      if @year
        todo = SchoolSetup::Steps.new(@year).call[:steps].first(SchoolSetup::Steps::STEPS.size).reject { it[:done] }
        todo = todo.reject { Money::SETUP.include?(it[:key]) }
        if todo.any?
          out << { kind: "setup", title: "#{SchoolDashboard.plural(todo.size, 'setup step')} not done", detail: todo.map { it[:label] }.join(", "),
                   step: todo.first[:key] }
        end
      end
      none = routes.values.flatten.count { bus_of(it).nil? }
      out << { kind: "no_bus", title: "#{SchoolDashboard.plural(none, 'trip')} without a bus", detail: "Assign a vehicle in Route Plans" } if none.positive?
      req = Stop.where(library_status: "pending", owner_school: @school).count
      out << { kind: "stop_requests", title: "#{SchoolDashboard.plural(req, 'pending stop request')}", detail: "Waiting for review in the Stop Library" } if req.positive?
      out
    end

    # Holidays, special days, public holidays on operating days and term starts / ends in the next 3 months (6 at most).
    def upcoming
      return [] unless @year

      lim = (@today.beginning_of_month >> 3)
      inside = ->(d) { d && d > @today && d < lim }
      out = []
      @year.holidays.each { |h| out << { date: h.starts_on, kind: "holiday", title: h.name.presence || "School holiday", ends_on: h.ends_on } if inside.(h.starts_on) }
      @year.special_days.each do |s|
        next unless inside.(s.date)

        out << { date: s.date, kind: "special_day", title: SPECIAL[s.kind], time: s.time_hm, detail: s.description.presence }
      end
      PublicHoliday.between(@today + 1, lim - 1).each do |p|
        out << { date: p.date, kind: "public_holiday", title: p.name } if @year.operating_days.include?(p.date.cwday)
      end
      @year.terms.each do |t|
        name = "#{@year.period_label} #{t.position}"
        out << { date: t.starts_on, kind: "term_start", title: "#{name} starts" } if inside.(t.starts_on)
        out << { date: t.ends_on, kind: "term_end", title: "#{name} ends" } if inside.(t.ends_on)
      end
      out.sort_by { it[:date] }.first(6)
    end
  end
end
