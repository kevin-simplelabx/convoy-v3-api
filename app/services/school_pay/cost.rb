# What a school's routes cost for a month, per operator (port of costVals + routeCost): every route of the plans running
# in the month, split where its regular bus moves to another operator. Each school day the route runs earns the day's
# price (the route's own price, else the school's default for the bus size: fixed monthly, or a base for some riders
# plus each rider above; plus the bus attendant when one is needed) over the month's school days (calendar days for a
# break month or when part months go by calendar days), times the Operator Pay scheme's share of the month, times the
# retainer earned in a break month. A replacement bus we arranged at a daily rate is taken off the regular operator
# and paid to the replacement's operator (auto lines). Operator nil = the company's own buses; "none" = no bus.
module SchoolPay
  class Cost < ApplicationService
    Row = Struct.new(:route, :plan, :key, :operator, :vehicle, :price, :unpriced, :amount, :days, :of, :brk, :earned, :rate, :from, :to, :note, keyword_init: true)

    def initialize(school, month)
      @school = school
      @month = month.beginning_of_month
      @last = @month.end_of_month
    end

    # What some routes cost a full month at the prices on a day (School Dashboard: a plan to be adopted against the current).
    def self.monthly(school, routes, day) = new(school, day).monthly(routes, day)

    def monthly(routes, day)
      prices!
      routes.sum(0.to_d) { price(it, day) || 0 }
    end

    def call
      @pay = @school.operator_pay || SchoolOperatorPay.new(school: @school)
      prices!
      @years = @school.academic_years.includes(:terms, :holidays).to_a
      @ph = PublicHoliday.between(@month, @last).pluck(:date).to_set
      @days = (@month..@last).select { school_day?(it) }
      @earned = OperatorPays::Earned.new(@school, @pay)
      routes = SchoolRoute.joins(:plan).where(school_plans: { school_id: @school.id, in_use: true })
                          .where("school_plans.effective_from <= ? AND (school_plans.effective_to IS NULL OR school_plans.effective_to >= ?)", @last, @month)
                          .includes(:plan, :prices, replacements: { vehicle: :operator }, vehicle_changes: { vehicle: :operator })
                          .order("school_plans.session", :number).to_a
      rows = []
      auto = Hash.new { |h, k| h[k] = [] }
      routes.each do |r|
        segs = segments(r)
        segs.each_with_index { |sg, i| rows << row(r, sg, segs, i) }
        replacements(r, segs, auto)
      end
      by = rows.group_by(&:key).transform_values { |l| { operator: l.first.operator, routes: l.size, amount: l.sum(0.to_d, &:amount) } }
      { month: @month, paid_month: @pay.rate(@month.month).positive?, school_days: @days.size, rows:, by_operator: by, auto: auto.to_h,
        total: rows.sum(0.to_d, &:amount), priced: rows.count(&:price), routes: rows.size }
    end

    private

    def school_day?(d)
      y = @years.find { (it.starts_on..it.ends_on).cover?(d) }
      y ? y.school_day?(d) : d.on_weekday? && !@ph.include?(d)
    end

    def on?(plan, d) = plan.effective_from <= d && (plan.effective_to.nil? || d <= plan.effective_to)

    def vehicle_on(route, d) = route.vehicle_changes.select { it.effective_from <= d }.last&.vehicle
    def key_of(v) = v.nil? ? "none" : (v.operator_id || "own")

    # The route's month split where its regular bus moves to another operator.
    def segments(route)
      v = vehicle_on(route, @month)
      out = [ { from: @month, to: @last, vehicle: v, key: key_of(v) } ]
      route.vehicle_changes.select { it.effective_from > @month && it.effective_from <= @last }.each do |c|
        last = out.last
        if key_of(c.vehicle) == last[:key]
          last[:vehicle] = c.vehicle
          next
        end
        last[:to] = c.effective_from - 1
        out << { from: c.effective_from, to: @last, vehicle: c.vehicle, key: key_of(c.vehicle) }
      end
      out
    end

    def row(route, sg, segs, i)
      plan = route.plan
      rate = @pay.rate(@month.month)
      brk = @pay.break_months.include?(@month.month) || @days.empty?
      base = brk || @pay.part_basis == "cal" ? (@month..@last).to_a : @days
      on = ->(d) { on?(plan, d) && d >= sg[:from] && d <= sg[:to] }
      act = base.select(&on)
      unpriced = false
      amount = act.sum(0.to_d) do |d|
        pr = price(route, d)
        unpriced = true if pr.nil?
        pr.to_d / base.size
      end
      earned = brk && @pay.break_pay == "earned" ? @earned.call(@month, on) : 1.to_d
      shown = price(route, @days.last || @month.change(day: 28))
      note = if segs.size > 1
               i.positive? ? "Took over from #{name_of(segs[i - 1])} on #{fmt(sg[:from])}" : "Moved to #{name_of(segs[i + 1])} from #{fmt(segs[i + 1][:from])}"
      end
      Row.new(route:, plan:, key: sg[:key], operator: sg[:vehicle]&.operator, vehicle: sg[:vehicle], price: shown, unpriced:,
              amount: rate.zero? ? 0.to_d : (amount * rate * earned).round(2), days: act.size, of: base.size, brk:, earned:, rate:,
              from: act.first, to: act.last, note:)
    end

    def prices!
      @rates = @school.bus_size_rates.index_by(&:bus_type)
      @policy = @school.attendant_policy
    end

    # The monthly price on a day: the route's own price, else the school's default for its bus size; plus the attendant.
    def price(route, d)
      own = route.prices.select { it.effective_from <= d }.last
      src = own || @rates[route.bus_type]
      return nil unless src

      mode = own ? own.mode : src.default_mode
      base = mode == "rider" ? src.base_price : src.monthly
      return nil if base.nil?

      over = mode == "rider" ? [ route.riders_count.to_i - src.riders_included.to_i, 0 ].max * src.per_rider.to_d : 0
      base + over + attendant(route)
    end

    def attendant(route)
      needs = @policy&.needs || "statutory"
      law = SchoolBus.statutory_sizes.include?(route.bus_type)
      return 0 unless law || needs == "all" || (needs == "some" && Array(@policy&.sizes).include?(route.bus_type))

      rate = @rates[route.bus_type]
      ((@policy&.provided_by || "operator") == "operator" ? rate&.ba_operator : rate&.ba_us).to_d
    end

    # A replacement we arranged at a daily rate: off the regular operator (unless not deducted), to the replacement's operator.
    def replacements(route, segs, auto)
      route.replacements.each do |e|
        next unless e.arranged_by == "us" && e.daily_rate.to_d.positive? && e.starts_on <= @last && e.ends_on >= @month

        dd = @days.select { it >= e.starts_on && it <= e.ends_on && on?(route.plan, it) }
        next if dd.empty?

        seg = segs.find { dd.first.between?(it[:from], it[:to]) } || segs.last
        amount = (e.daily_rate * dd.size).round(2)
        why = "#{e.vehicle.plate}#{" (#{e.vehicle.operator.name})" if e.vehicle.operator}, #{dd.size} day#{'s' unless dd.size == 1} at S$#{format('%.2f', e.daily_rate)}/day#{". #{e.reason}" if e.reason.present?}"
        line = { id: "rp-#{e.id}", auto: true, sign: -1, kind: "Replacement bus we arranged", adj_on: dd.first, route: route.label, amount:, days: dd.size, reason: why }
        auto[seg[:key]] << line if e.deduct_from_operator
        other = e.vehicle.operator_id
        auto[other] << line.merge(id: "rp-#{e.id}-a", sign: 1, kind: "Replacement bus for #{name_of(seg)}") if other && other != seg[:key]
      end
    end

    def name_of(seg) = seg[:vehicle]&.operator&.name || (seg[:vehicle] ? "Our buses" : "Not assigned")
    def fmt(d) = d.strftime("%d/%m/%Y")
  end
end
