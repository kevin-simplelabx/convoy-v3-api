# A driver's pay for a part of a month on one pay scheme (port of DriverPay.simulate, see .notes/apps/convoy-os/hr/inventory.md § 8.3).
# Earnings and the Salary Simulator both call it: Pay::Month splits a month into parts by scheme and adds them up.
#
# Fixed pay (basic, monthly pay, shift salary, the guarantee, the route retainer) and the monthly targets follow the
# part of the month: a part of 10 of 30 days gets a third. Jobs are paid by the rate plan of the scheme at the
# vehicle type of each job. Amounts are BigDecimal, rounded to cents at the end.
module Pay
  class Engine
    WDAYS = %w[sun mon tue wed thu fri sat].freeze

    # kind :trip (start, tv) or :hours (start, end; disposal and hourly trips). ref = what the line pays for (a run).
    Job = Struct.new(:date, :kind, :start, :finish, :tv, :vehicle_type_id, :ref, :route, keyword_init: true)

    Result = Struct.new(:from, :to, :scheme, :total, :parts, :rows, :days, :weeks, :job_pay, :trips, :hours, :penalty, keyword_init: true)

    # scheme: PayScheme (nil = no scheme: jobs earn nothing). jobs: [Job]. routes: [{ minutes:, start: }] the school routes
    # the driver is regular on; school_holidays: a Range of dates (simulator). rejected: jobs turned down in the month.
    # route_days: count the routes on every school weekday (simulator); Earnings sends the route runs as jobs instead.
    def initialize(scheme:, from:, to:, month_days:, holidays:, jobs:, routes: [], school_holidays: nil, rejected: 0, route_days: true)
      @s = scheme
      @from = from
      @to = to
      @dates = (from..to).to_a
      @factor = @dates.size.to_d / month_days
      @holidays = holidays
      @jobs = jobs.group_by(&:date)
      @routes = routes
      @school_holidays = school_holidays
      @rejected = rejected.to_i
      @route_days = route_days
      @lookup = scheme&.rate_plan ? RateLookup.new(scheme.rate_plan, holidays:) : nil
    end

    def call
      return unpaid unless @s

      setup
      @dates.each { |d| day(d) }
      finish
    end

    private

    # ---- setup ------------------------------------------------------------------------------------------------------

    def setup
      t = @s.scheme_type
      @pen = @s.has_rejection_penalty? && @rejected > @s.rejection_allowed_jobs
      @inc = !@pen || @s.rejection_keeps_incentives?
      @fb = @pen && t != "basic_plus_trips"
      @base = base_amount * @factor
      @g = @s.guaranteed_amount * @factor
      @has_g = t == "basic_plus_trips" && @s.has_guarantee? && !@pen
      bands = @s.route_bands.sort_by { |b| b.up_to_minutes || Float::INFINITY }
      @route_amounts = @routes.map { |r| (bands.find { |b| b.up_to_minutes.nil? || r[:minutes].to_i <= b.up_to_minutes } || bands.last)&.monthly_amount.to_d }
      @monthly_commitment = (@s.monthly_trips * @factor).ceil

      @trip_pay = @disp_pay = @d_inc = @w_inc = @m_inc = @pg_inc = @on_top = 0.to_d
      @basis = @base
      @trips = @hours = @covered = @g_count = @w_trips = 0.to_d
      @trip_by = Hash.new(0.to_d)
      @hour_by = Hash.new(0.to_d)
      @days = {}
      @weeks = []
      @job_pay = Hash.new(0.to_d)
      @w_start = @dates.first
    end

    # ---- one day ----------------------------------------------------------------------------------------------------

    def day(d)
      if d.monday?
        @w_trips = 0.to_d
        @w_start = d
      end
      lines = []
      on_top = on_top_day?(d)
      @day_count = 0.to_d
      @day_basis = 0.to_d
      sub = 0.to_d
      day_trips = 0.to_d

      n_routes = route_count(d)
      if n_routes.positive?
        c0 = [ n_routes, avail(d) ].min
        @covered += c0
        @day_count += n_routes
        day_trips += n_routes
        count_trips(n_routes)
        lines << line("Routes", "#{n_routes} school #{'route'.pluralize(n_routes)} #{school_day?(d) ? 'counted as trips, paid by the route retainer' : 'counted in the school holidays'}" \
                                "#{c0.positive? ? ", #{num(c0)} included in base pay" : ''}", 0)
      end

      block = nil
      events(d).each do |ev|
        if ev[:kind] == :trip
          lines << flush(block, on_top) if block
          block = nil
          amt, ln, units = trip(d, ev[:job], on_top)
          sub += amt
          day_trips += units
          lines << ln
        else
          amt, step = hour_step(d, ev, on_top)
          sub += amt
          if block && block[:period] == step[:period] && block[:rate] == step[:rate] && block[:covered].positive? == step[:covered].positive? && block[:finish] == ev[:start]
            %i[hours covered amount pg].each { |k| block[k] += step[k] }
            block[:finish] = ev[:finish]
          else
            lines << flush(block, on_top) if block
            block = step.merge(start: ev[:start], finish: ev[:finish])
          end
        end
      end
      lines << flush(block, on_top) if block

      sub += weekly_target(d, lines)
      sub += monthly_target(d, lines)
      @basis += @day_basis
      @days[d] = { lines:, amount: sub.round(2), trips: day_trips, on_top:, holiday: @holidays.include?(d) }
    end

    def events(d)
      (@jobs[d] || []).sort_by(&:start).flat_map do |j|
        next [ { kind: :trip, start: j.start, job: j } ] if j.kind == :trip

        finish = j.finish > j.start ? j.finish : j.finish + 1440
        (j.start...finish).step(60).map { |h| { kind: :hour, start: h, finish: [ h + 60, finish ].min, job: j } }
      end.sort_by { |e| e[:start] }
    end

    def trip(d, job, on_top)
      return retained_route(d, job) if job.route && @s.school_routes_pay? && !@route_days

      tv = [ job.tv.to_d, 0 ].max
      r = rate(d, job.start, job.vehicle_type_id)
      price = r[:per_trip]
      c = shift_on?(d, job.start) ? tv : [ tv, avail(d) ].min
      pay = tv - c
      core = price * pay
      @trip_by[[ on_top, price ]] += pay if pay.positive?
      vol = @inc && @s.has_daily_volume_incentive? && pay.positive? ? volume(price, pay) : 0.to_d
      pg = boost(core + vol, pay)
      amt = core + vol + pg
      @trip_pay += core
      @d_inc += vol
      @pg_inc += pg
      @covered += c
      if on_top
        @on_top += amt
      else
        @day_basis += core + (@s.daily_volume_in_guarantee? ? vol : 0)
      end
      @day_count += tv
      count_trips(tv)
      @job_pay[job.ref] += amt if job.ref
      detail = trip_detail(r[:name], tv, c, vol, pg, on_top)
      [ amt, line(Clock.hm(job.start), "#{job.route ? 'School route | ' : ''}#{detail}", amt, c >= tv ? nil : "#{num(pay)} x #{money(price)}", ref: job.ref), tv ]
    end

    def trip_detail(period, tv, covered, vol, pg, on_top)
      return "Included in base pay" if covered >= tv

      [ period, (tv == 1 ? nil : "trip value #{num(tv)}"), (covered.positive? ? "#{num(covered)} included" : nil),
        (vol.positive? ? "+#{money(vol)} daily volume" : nil), (pg.positive? ? "+#{money(pg)} after guarantee" : nil),
        (on_top ? "on top" : nil) ].compact.join(" | ")
    end

    # A school route run under the route retainer: counts as a trip, paid by the retainer.
    def retained_route(d, job)
      c = [ 1, avail(d) ].min
      @covered += c
      @day_count += 1
      count_trips(1)
      @job_pay[job.ref] += 0 if job.ref
      [ 0.to_d, line(Clock.hm(job.start), "School route | paid by the route retainer", 0, ref: job.ref), 1 ]
    end

    def hour_step(d, ev, on_top)
      step = (ev[:finish] - ev[:start]).to_d / 60
      r = rate(d, ev[:start], ev[:job].vehicle_type_id)
      price = @s.shift_based? && !@fb && @s.overtime_by_hourly_rate? ? @s.shift_overtime_hourly_rate : r[:per_hour]
      c = 0.to_d
      if shift_on?(d, ev[:start] % 1440)
        c = step
      elsif @s.disposal_counts_as_trips? && !@s.shift_based?
        c = [ step, avail(d) ].min
        @day_count += c
        @g_count += c
      end
      pay = step - c
      core = price * pay
      pg = boost(core, pay)
      amt = core + pg
      @hour_by[[ on_top, price ]] += pay if pay.positive?
      @disp_pay += core
      @pg_inc += pg
      @hours += step
      @covered += c
      on_top ? @on_top += amt : @day_basis += core
      @job_pay[ev[:job].ref] += amt if ev[:job].ref
      [ amt, { period: r[:name], rate: price, hours: step, covered: c, amount: amt, pg:, ref: ev[:job].ref } ]
    end

    def flush(b, on_top)
      detail = [ "By the hour", b[:period], (b[:covered].positive? ? "#{num(b[:covered])} h included" : nil),
                 (b[:pg].positive? ? "+#{money(b[:pg])} after guarantee" : nil), (on_top ? "on top" : nil) ].compact.join(" | ")
      line("#{Clock.hm(b[:start])} to #{Clock.hm(b[:finish])}", detail, b[:amount], "#{num(b[:hours] - b[:covered])} h x #{money(b[:rate])}", ref: b[:ref])
    end

    def weekly_target(d, lines)
      return 0 unless @inc && @s.has_weekly_target_incentive? && d.sunday? && @w_start.monday?

      tier = @s.weekly_tiers.select { |t| @w_trips >= t.target_trips }.max_by(&:target_trips)
      amt = tier ? target_amount(tier, @w_trips) : 0.to_d
      @weeks << { from: @w_start, to: d, trips: @w_trips, target: tier&.target_trips, first_target: @s.weekly_tiers.map(&:target_trips).min, amount: amt.round(2) }
      return 0 unless amt.positive?

      @w_inc += amt
      @day_basis += amt if @s.weekly_target_in_guarantee?
      lines << line("Week", "Weekly target | #{num(@w_trips)} trips, target #{tier.target_trips}", amt)
      amt
    end

    def monthly_target(d, lines)
      return 0 unless @inc && @s.has_monthly_target_incentive? && d == @dates.last

      tier = @s.monthly_tiers.select { |t| @trips >= (t.target_trips * @factor).ceil }.max_by(&:target_trips)
      return 0 unless tier

      amt = target_amount(tier, @trips)
      @m_inc += amt
      @day_basis += amt if @s.monthly_target_in_guarantee?
      lines << line("Month", "Monthly target | #{num(@trips)} trips, target #{(tier.target_trips * @factor).ceil}", amt)
      amt
    end

    # ---- month end --------------------------------------------------------------------------------------------------

    def finish
      rt_pay = @s.school_routes_pay? ? @route_amounts.sum(0.to_d) * @factor : 0.to_d
      @basis += rt_pay if @s.school_routes_in_guarantee?
      top_up = @has_g && @basis < @g ? @g - @basis : 0.to_d
      parts = { base: @base, route_pay: rt_pay, trip_pay: @trip_pay, hour_pay: @disp_pay, daily_volume: @d_inc, weekly_target: @w_inc,
                monthly_target: @m_inc, after_guarantee: @pg_inc, top_up: }.transform_values { |v| v.round(2) }
      Result.new(from: @from, to: @to, scheme: @s, total: parts.values.sum, parts:, rows: rows(rt_pay, top_up), days: @days, weeks: @weeks,
                 job_pay: @job_pay.transform_values { |v| v.round(2) }, trips: @trips, hours: @hours, penalty: @pen)
    end

    def rows(rt_pay, top_up)
      t = @s.scheme_type
      [
        row(base_label, @base, part: @factor < 1 ? "#{@dates.size} of #{(@dates.size / @factor).round} days" : nil),
        row("Trips Counted", nil, text: "#{num(@trips)} trips"),
        (row("Included in Base Pay", nil, text: "#{num(@covered)} #{t == 'shift_based' ? 'trips or hours in shift' : 'trips or hours'}") if @covered.positive?),
        (row("School Route Pay", rt_pay, text: "#{@route_amounts.size} x #{money(@route_amounts.sum(0) / [ @route_amounts.size, 1 ].max)}") if rt_pay.positive?),
        row("Trip Pay", @trip_pay, units: by_rate(@trip_by)),
        (row("Disposal Hours", nil, text: "#{num(@hours)} h") if @hours.positive?),
        (row("Disposal Pay", @disp_pay, units: by_rate(@hour_by)) if @hours.positive?),
        (row("Daily Volume Incentives", @d_inc) if @d_inc.positive?),
        (row("Weekly Target Incentives", @w_inc) if @w_inc.positive?),
        (row("Monthly Target Incentives", @m_inc) if @m_inc.positive?),
        (row("After-Guarantee Boost", @pg_inc) if @pg_inc.positive?),
        (row("Counted Towards Guarantee", @basis, text: "#{money(@basis)} of #{money(@g)}") if @has_g),
        (row("Paid on Top of Guarantee", @on_top) if @has_g && @on_top.positive?),
        (row("Guarantee Top-Up", top_up) if top_up.positive?),
        (row("Rejection Penalty", nil, text: "Triggered. #{t == 'basic_plus_trips' ? 'No guarantee' : 'Paid as Basic + Trips'}#{@inc ? ', incentives kept' : ', no incentives'}") if @pen)
      ].compact
    end

    # Basic + Trips: basic salary; with the rejection penalty: the fallback basic; else the monthly pay or shift salary.
    def base_amount
      return @s.basic_salary if @s.basic_plus_trips?
      return @s.rejection_fallback_basic if @pen

      @s.monthly_with_minimum? ? @s.monthly_pay_amount : @s.shift_salary
    end

    def base_label
      return "Basic Salary" if @s.basic_plus_trips?
      return "Fallback Basic Salary" if @pen

      @s.monthly_with_minimum? ? "Monthly Pay" : "Shift Salary"
    end

    def unpaid
      job_pay = @jobs.values.flatten.filter_map { |j| [ j.ref, 0.to_d ] if j.ref }.to_h
      Result.new(from: @from, to: @to, scheme: nil, total: 0.to_d, parts: {}, rows: [ row("No Pay Scheme", 0, text: "No pay scheme on these days, so jobs earn nothing") ],
                 days: {}, weeks: [], job_pay:, trips: @jobs.values.flatten.sum { |j| j.tv.to_d }, hours: 0, penalty: false)
    end

    # ---- rules ------------------------------------------------------------------------------------------------------

    def rate(d, minutes, type_id)
      return { name: "No rate plan", per_trip: 0.to_d, per_hour: 0.to_d } unless @lookup && type_id

      r = @lookup.rate(d, minutes, type_id)
      { name: r[:period]&.name || "No period", per_trip: r[:per_trip], per_hour: r[:per_hour] }
    end

    # Trips (or hours) of the day the fixed pay still covers.
    def avail(d)
      return 0 if @fb

      case @s.scheme_type
      when "basic_plus_trips"
        @s.basic_covers_daily_trips? && in_schedule?(d, @s.basic_covered_schedule, @s.basic_cover_ph?) ? [ @s.basic_covered_daily_trips - @day_count, 0 ].max : 0
      when "monthly_with_minimum"
        if @s.minimum_monthly? then [ @monthly_commitment - @g_count, 0 ].max
        elsif in_schedule?(d, @s.monthly_schedule, @s.monthly_cover_ph?) then [ @s.monthly_daily_trips - @day_count, 0 ].max
        else 0
        end
      else 0
      end
    end

    # mon-fri always; all-days; mon-sat adds Sat; mon-fri-sun adds Sun; 6-days adds Sat, and Sun when Sat was a PH or had no jobs.
    def in_schedule?(d, schedule, include_ph)
      return false if @holidays.include?(d) && !include_ph
      return true if (1..5).cover?(d.wday) || schedule == "all-days"
      return d.saturday? if schedule == "mon-sat"
      return d.sunday? if schedule == "mon-fri-sun"
      return d.saturday? || (d.sunday? && (@holidays.include?(d - 1) || (@jobs[d - 1] || []).empty?)) if schedule == "6-days"

      false
    end

    def shift_on?(d, minutes)
      @s.shift_based? && !@fb && !@holidays.include?(d) && @s.shift_working_days.include?(WDAYS[d.wday]) &&
        minutes >= @s.shift_start_time && minutes < @s.shift_end_time
    end

    def on_top_day?(d)
      @has_g && ((@s.on_top_ph? && @holidays.include?(d)) || (@s.on_top_sat? && d.saturday?) || (@s.on_top_sun? && d.sunday?))
    end

    def volume(price, pay)
      n = @day_count.floor + 1
      tier = @s.volume_tiers.find { |t| n >= t.from_trip && (t.to_trip.nil? || n <= t.to_trip) }
      return 0.to_d unless tier

      case tier.boost_type
      when "flat" then tier.boost_value * pay
      when "percentage" then price * tier.boost_value / 100 * pay
      else [ (tier.boost_value - price) * pay, 0 ].max
      end
    end

    # After-guarantee boost once what counts towards the guarantee has reached it.
    def boost(amount, units)
      return 0.to_d unless @inc && @s.has_post_guarantee_boost? && @has_g && @basis + @day_basis >= @g && units.positive?

      v = @s.post_guarantee_boost_value
      case @s.post_guarantee_boost_type
      when "percentage" then amount * v / 100
      when "flat" then v * units
      else [ (v * units) - amount, 0 ].max
      end
    end

    def target_amount(tier, trips) = tier.pay_lump_sum? ? tier.amount : trips * tier.amount

    # School routes counted as trips that day (weekdays, not PH): with the retainer in term time (and in school holidays
    # when counted); without it, routes are driven as jobs, and only counted in school holidays when switched on.
    def route_count(d)
      return 0 if !@route_days || @routes.empty? || !(1..5).cover?(d.wday) || @holidays.include?(d)

      if @s.school_routes_pay? then @s.school_routes_count? || school_day?(d) ? @routes.size : 0
      else !school_day?(d) && @s.school_routes_count? ? @routes.size : 0
      end
    end

    def school_day?(d) = !@school_holidays&.cover?(d)

    def count_trips(n)
      @trips += n
      @w_trips += n
      @g_count += n
    end

    # ---- output -----------------------------------------------------------------------------------------------------

    def line(time, detail, amount, units = nil, ref: nil) = { time:, detail:, amount: amount.to_d.round(2), units:, ref: }

    def row(label, amount, text: nil, part: nil, units: nil)
      { label:, amount: amount&.to_d&.round(2), text:, part:, units: }.compact
    end

    # [{ rate, units, on_top }] largest first.
    def by_rate(h) = h.map { |(on_top, rate), units| { rate: rate.round(2), units: units.round(2), on_top: } }.sort_by { |x| -x[:units] }

    def num(n) = n.to_d.round(2).to_s("F").sub(/\.0\z/, "")
    def money(n) = "S$#{format('%.2f', n.to_d.round(2))}"
  end
end
