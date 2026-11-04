# Reports > Shuttle Report of one Corporate Shuttle trip for a period (month m|2026-10, quarter q|2026-4, year y|2026):
# KPIs against the period before, utilisation by timing, stop activity, the 12-month trend; and the month grids
# (riders per timing per day, on-time per stop).
module Reports
  class Shuttle
    def initialize(trip:, period:, today: Date.current)
      @trip = trip
      @today = today
      @from, @to, @label = self.class.range(period, today)
      @late = trip.client&.on_time_allowance || 3
    end

    # [from, to, label] of a period value; nil period = last month.
    def self.range(value, today = Date.current)
      kind, v = value.to_s.split("|")
      case kind
      when "q"
        y, q = v.split("-").map(&:to_i)
        from = Date.new(y, ((q - 1) * 3) + 1, 1)
        [ from, (from >> 2).end_of_month, "Q#{q} #{y}" ]
      when "y" then [ Date.new(v.to_i, 1, 1), Date.new(v.to_i, 12, 31), v ]
      else
        from = v ? Date.strptime(v, "%Y-%m") : today.prev_month.beginning_of_month
        [ from, from.end_of_month, from.strftime("%B %Y") ]
      end
    rescue ArgumentError, Date::Error
      raise ApplicationService::Error, "Period must look like m|2026-10, q|2026-4 or y|2026"
    end

    # Period options: the last 12 months, 5 quarters, 2 years.
    def self.options(today = Date.current)
      months = (1..12).map { |i| d = today.beginning_of_month << i; { value: "m|#{d.strftime('%Y-%m')}", label: d.strftime("%B %Y") } }
      q0 = today.beginning_of_quarter
      quarters = (0..4).map { |i| d = q0 << (i * 3); q = ((d.month - 1) / 3) + 1; { value: "q|#{d.year}-#{q}", label: "Q#{q} #{d.year}" } }
      months + quarters + [ today.year, today.year - 1 ].map { |y| { value: "y|#{y}", label: y.to_s } }
    end

    def summary
      runs = runs(@from, @to)
      before = runs(*previous)
      year_ago = last_year
      plate = runs.reverse.find { it.occ.vehicle }&.occ&.vehicle&.plate
      { trip: { id: @trip.id, title: @trip.title, client: @trip.client&.name, days_text: @trip.decorate.days_text, plate: },
        period: { from: @from, to: @to, label: @label, last_year: year_ago && { from: year_ago[0], to: year_ago[1], label: year_ago[2] } },
        on_time_allowance: @late, early_minutes: ShuttleRuns::EARLY, kpis: kpis(runs, before, year_ago && runs(year_ago[0], year_ago[1])), timings: timings(runs),
        stop_activity: stop_activity(runs), trend: trend, has_data: runs.any? }
    end

    # The month grids: riders per timing per day, and each run's stops (time, status) per day.
    def grid(month)
      from = month.beginning_of_month
      runs = runs(from, from.end_of_month)
      dates = runs.map(&:date).uniq.sort
      by_timing = runs.group_by { |r| r.timing[:key] }
      rows = by_timing.values.sort_by { |l| [ l.first.timing[:direction], l.first.timing[:position] ] }.map do |list|
        t = list.first.timing
        cells = dates.map { |d| list.find { |r| r.date == d }&.then { |r| { date: d, occurrence_id: r.occ.id, riders: r.riders, amended: r.stops.any? { |s| s[:amended] } } } }
        { timing: t, cells:, total: list.sum(&:riders), avg: avg(list.sum(&:riders), list.size), max: list.map(&:riders).max,
          util: util(list), stops: list.first.stops.map { |s| { name: s[:name], planned: Clock.hm(s[:planned]) } },
          on_time: dates.map { |d| list.find { |r| r.date == d }&.then { |r| { date: d, occurrence_id: r.occ.id, stops: r.stops.map { |s| s.slice(:status, :amended).merge(arrived: Clock.hm(s[:arrived])) } } } } }
      end
      counts = status_counts(runs)
      worst_t = rows.min_by { |r| otp(r[:on_time].compact.flat_map { |x| x[:stops] }) || 1 }
      worst_d = dates.min_by { |d| otp(runs.select { |r| r.date == d }.flat_map(&:stops)) || 1 }
      { month: from.strftime("%Y-%m"), dates:, rows:, on_time: counts.merge(pct: otp(runs.flat_map(&:stops))),
        worst_timing: worst_t&.dig(:timing, :dep), worst_day: worst_d }
    end

    private

    def runs(from, to) = ShuttleRuns.call(trip: @trip, from:, to:, late: @late, today: @today)

    def previous
      months = ((@to.year * 12) + @to.month) - ((@from.year * 12) + @from.month) + 1
      [ @from << months, (@from - 1) ]
    end

    # The same period a year before (none for a year: the year before is the period before).
    def last_year
      return nil if @to - @from > 100

      from = @from << 12
      [ from, (@to << 12).end_of_month, @label.sub(@from.year.to_s, from.year.to_s) ]
    end

    # KPI tiles: change on the period before and on the same period last year (`*_change_ly`, nil for a year), the
    # late / left-early stop counts and how many runs a service day has.
    def kpis(runs, before, year_ago)
      now = totals(runs)
      prev = totals(before)
      ly = (totals(year_ago) if year_ago.present?) # nil with no runs a year before, as the prototype hides it
      counts = status_counts(runs)
      days = runs.map(&:date).uniq.size
      { utilisation: now[:util], utilisation_change: change(now[:util], prev[:util]), utilisation_change_ly: ly && change(now[:util], ly[:util]),
        riders: now[:riders], riders_change: change(now[:riders], prev[:riders]), riders_change_ly: ly && change(now[:riders], ly[:riders]),
        avg_per_day: now[:avg_day], on_time: now[:otp], on_time_change: change(now[:otp], prev[:otp]), on_time_change_ly: ly && change(now[:otp], ly[:otp]),
        late: counts["late"], left_early: counts["edep"], service_days: now[:days], runs: runs.size,
        runs_a_day: days.positive? ? runs.map { it.timing[:key] }.uniq.size : 0, seats: runs.map(&:seats).max }
    end

    def totals(runs)
      days = runs.map(&:date).uniq.size
      riders = runs.sum(&:riders)
      { riders:, days:, avg_day: avg(riders, days), util: util(runs), otp: otp(runs.flat_map(&:stops)) }
    end

    def timings(runs)
      list = runs.group_by { |r| r.timing[:key] }.values.map do |l|
        t = l.first.timing
        { dep: t[:dep], direction: t[:direction], direction_label: direction_label(t[:direction]), utilisation: util(l), riders: l.sum(&:riders),
          avg: avg(l.sum(&:riders), l.size), max: l.map(&:riders).max }
      end.sort_by { |r| -r[:utilisation].to_f }
      list.first[:tag] = "Busiest" if list.size > 1
      list.last[:tag] = "Quietest" if list.size > 1
      list
    end

    # Boardings at each pick-up per direction (the destination is left out). Only for routes with 3 or more stops.
    def stop_activity(runs)
      return [] if @trip.stops.size < 3

      runs.group_by { |r| r.timing[:direction] }.sort.map do |dir, list|
        counts = Hash.new(0)
        list.each { |r| r.stops[0...-1].each { |s| counts[s[:name]] += s[:boarded] } }
        total = counts.values.sum
        { direction: dir, label: direction_label(dir), stops: counts.map { |name, n| { name:, boarded: n, pct: total.positive? ? (n * 100.0 / total).round(1) : 0 } } }
      end
    end

    def trend
      (0..11).map do |i|
        m = @to.beginning_of_month << (11 - i)
        list = runs(m, m.end_of_month)
        { month: m.strftime("%Y-%m"), riders: list.sum(&:riders), utilisation: util(list), on_time: otp(list.flat_map(&:stops)),
          in_period: m >= @from.beginning_of_month && m <= @to }
      end
    end

    def direction_label(dir)
      stops = @trip.stops_in(dir)
      "To #{stops.last&.name || (dir == 1 ? 'destination' : 'origin')}"
    end

    def status_counts(runs) = %w[ok early late edep skip].index_with { |k| runs.sum { |r| r.stops.count { |s| s[:status] == k } } }

    # On time = (ok + early) / (ok + early + late + edep); skipped stops are left out. nil with nothing to count.
    def otp(stops)
      good = stops.count { |s| %w[ok early].include?(s[:status]) }
      counted = good + stops.count { |s| %w[late edep].include?(s[:status]) }
      counted.positive? ? (good * 100.0 / counted).round(1) : nil
    end

    def util(runs)
      seats = runs.sum(&:seats)
      seats.positive? ? (runs.sum(&:riders) * 100.0 / seats).round(1) : nil
    end

    def avg(total, n) = n.positive? ? (total.to_f / n).round(1) : 0
    def change(now, before) = now && before ? (now - before).round(1) : nil
  end
end
