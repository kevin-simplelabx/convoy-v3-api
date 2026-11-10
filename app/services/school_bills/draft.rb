# What Convoy would bill for a billing period of a school's academic year (port of billDraft + the family bill charge of
# fiDraft): the riders on the route plans in use when the period starts, plus those who join before it ends.
# - Parents pay: each child's fare (tier by straight-line km from school, or the zone they live in; 2-way, 1-way or
#   AM / PM by the sessions they ride; the small-bus fare or the bus-size column for the days their bus was that size;
#   the Extra Charges of the bill month) on their family's bill. A child who joins during the period pays by the start
#   rule (prorate by school days, the full period, or half from the 16th); a child whose fees stop during it pays to
#   that day (prorated when the policy's refund basis is days). The month on a request's first invoice is skipped.
# - School pays per rider: the same lines on one bill to the school. Per bus: each bus size × its rate, plus route
#   charges and changes during the period.
# Returns { error } or { period, due_on, bills: [{ payer, family, lines: [{ rid, child_name, description, amount, note }], amount }],
# skipped: [text], unlinked: n }.
module SchoolBills
  class Draft < ApplicationService
    RULES = %w[prorate full half].freeze

    # expected: what the period earns (School Dashboard revenue) — every rider, linked to a family or not, first invoice month
    # included, on one bill.
    def initialize(year, index, rule: FinanceSetting.current.school_bill_start_rule, expected: false)
      @year = year
      @school = year.school
      @i = index
      @rule = rule
      @expected = expected
    end

    def call
      @table = @year.fare_table
      return { error: "Lock the Bus Fares for this year first" } unless @table&.locked?

      @periods = FareTables.periods(@year, @table)
      @months = FareTables.bill_months(@year, @table)
      return { error: "No billing period #{@i + 1} in AY #{@year.key}" } unless @periods[@i]

      @start = period_start(@i)
      @end = @i + 1 < @periods.size ? period_start(@i + 1) - 1 : @year.ends_on
      @month = @months[@i]
      @policy = @school.policy_versions.in_use_on(Date.current)
      @adjustments = @school.fare_adjustments.where(academic_year: @year).includes(:targets).to_a
      @skipped = []
      bills = @table.per_bus? ? bus_bills : rider_bills
      { period: period, due_on: SchoolBills.due_on(@policy, @start), bills:, skipped: @skipped, unlinked: @unlinked || 0 }
    end

    private

    def period
      p = @periods[@i]
      { index: @i, label: "#{p[:label]} | #{FareTables::MONTHS[@month.month - 1]} #{@month.year}", starts_on: @start, ends_on: @end, month: @month }
    end

    def period_start(i) = @table.cycle == "month" ? @months[i] : (@periods[i][:starts_on] || @months[i])

    # ---- parents / school per rider ----

    def rider_bills
      fares = FareTables::Calc.call(@table, @periods)
      tiers = @table.tiers.includes(:areas).to_a
      first = riders_on(@start)
      later = riders_on(@end).except(*first.keys)
      riders = @school.riders.where(rid: first.keys | later.keys).index_by(&:rid)
      mix = mix_days if @table.small_on || @table.by_size
      reqs = @school.bus_requests.where(academic_year: @year).includes(:first_bill).to_a
      family_of = FamilyRider.where(school: @school, rid: riders.keys).includes(:family).to_h { [ it.rid, it.family ] }
      lines = []
      [ [ first, false ], [ later, true ] ].each do |list, join|
        list.each do |rid, sessions|
          r = riders[rid] or next
          fare = fare_of(r, sessions, fares, tiers, mix&.dig(rid)) or next
          line = charge(r, fare, reqs, join) or next
          lines << line
        end
      end
      return [ bill("school", nil, lines) ].reject { it[:lines].empty? } if @table.payer == "school" || @expected

      @unlinked = lines.count { family_of[it[:rid]].nil? }
      lines.select { family_of[it[:rid]] }.group_by { family_of[it[:rid]] }.map { |fam, ls| bill("family", fam, ls) }.sort_by { it[:family].name }
    end

    def bill(payer, family, lines) = { payer:, family:, lines:, amount: lines.sum(0.to_d) { it[:amount] }.round(2) }

    # rid => sessions ("am" / "pm") of the riders on the AM / PM route plans in use on a day (and on the list then).
    def riders_on(day)
      on_list = SchoolRider.of_school_on(@school, day).pluck(:rid).to_set
      rows = SchoolRouteRider.joins(school_route: :plan).merge(plans_on(day)).pluck(:rid, "school_plans.session")
      rows.select { on_list.include?(it[0]) }.group_by(&:first).transform_values { it.map(&:last).to_set }
    end

    def plans_on(day)
      SchoolPlan.where(school: @school, in_use: true, session: %w[am pm]).where(effective_from: ..day)
                .where("school_plans.effective_to IS NULL OR school_plans.effective_to >= ?", day)
    end

    # rid => seats of the biggest bus the child was on each school day of the period.
    def mix_days
      days = (@start..@end).select { @year.school_day?(it) && (@i + 1 >= @periods.size || it <= @end) }
      out = Hash.new { |h, k| h[k] = [] }
      rows = SchoolRouteRider.joins(school_route: :plan).where(school_plans: { school_id: @school.id, in_use: true, session: %w[am pm] })
                             .pluck(:rid, "school_routes.seats", "school_plans.effective_from", "school_plans.effective_to")
      days.each do |d|
        rows.select { |_, _, f, t| f <= d && (t.nil? || t >= d) }.group_by(&:first).each { |rid, l| out[rid] << l.map { it[1] || 99 }.max }
      end
      out
    end

    def fare_of(rider, sessions, fares, tiers, seats)
      ti = FareTables::RiderFare.tier_index(@table, @school, rider, tiers)
      row = fares[ti] or return nil
      two = sessions.include?("am") && sessions.include?("pm")
      pick = ->(k) { FareTables::RiderFare.pick(@table, k, sessions) }
      std = pick.(row[:std]) or return nil
      bus = ""
      base = if @table.by_size && seats.present?
               cols = @table.size_columns.to_a
               counts = seats.tally.each_with_object(Hash.new(0)) { |(s, n), h| h[size_column(cols, s)] += n }
               bus = counts.map { |c, n| "#{size_label(cols, c)}#{" #{n} of #{seats.size} days" if n < seats.size}" }.join(", ")
               counts.sum(0.to_d) { |c, n| ((c.zero? ? std : pick.(row[:sizes][c - 1][:fares]) || std)[:periods][@i] || 0) * n / seats.size }
      elsif @table.by_size
               bus = size_label(@table.size_columns.to_a, 0)
               std[:periods][@i] || 0
      else
               small = seats.present? && row[:small] ? seats.count { it < @table.small_seats } : 0
               share = small.positive? ? small.to_d / seats.size : 0
               bus = share >= 1 ? "Small bus" : "Small bus #{small} of #{seats.size} days" if small.positive?
               ((std[:periods][@i] || 0) * (1 - share)) + (share.positive? ? (pick.(row[:small])[:periods][@i] || 0) * share : 0)
      end
      tier = tiers[ti]
      amount = FareTables.adjusted(base.to_d, @month, tier.id, @adjustments) + FareTables.one_offs(@month, tier.id, @adjustments)
      { amount: amount.round(2), tier: row[:label], trip: two ? "2-way" : (sessions.include?("am") ? "AM only" : "PM only"), bus: }
    end

    def size_column(cols, seats) = cols.index { it.max_seats && seats <= it.max_seats } || (cols.size - 1)
    def size_label(cols, i) = FareTables::Calc.new(@table, @periods).column_label(cols, i)

    # One child's line: the fare, less what is not charged when they join or stop during the period (port of famBills.charge).
    def charge(rider, fare, reqs, join)
      mine = reqs.select { it.school_rider_id == rider.id }
      first = !@expected && mine.find { it.kind == "new" && it.first_bill && it.start_on&.beginning_of_month == @month }
      return skip("#{rider.name}: this month is on the first invoice #{first.first_bill.number}") if first

      stop = mine.find { (it.kind == "stop" && %w[Stopping Stopped].include?(it.live_status)) || (it.kind == "adr" && it.status == "Stopped" && it.effective_on) }
      pay_to = stop ? (stop.pay_to || stop.last_on || (stop.kind == "adr" ? stop.effective_on - 1 : nil)) : (rider.ends_on if rider.ends_on && rider.ends_on < @end)
      return skip("#{rider.name}: service stopped #{pay_to.strftime('%d/%m/%Y')}") if pay_to && pay_to < @start

      total = days(@start, @end)
      from = join && rider.starts_on && rider.starts_on > @start ? rider.starts_on : @start
      amount = fare[:amount]
      notes = []
      if from > @start
        ridden = days(from, @end)
        part = start_part(amount, ridden, total, from)
        notes << "Joins #{from.strftime('%d/%m/%Y')}#{start_note(part < amount, ridden, total)}"
        amount = part
      end
      if pay_to && pay_to < @end
        ridden = days(from, pay_to)
        by_days = (@policy&.refund_basis || "days") == "days"
        amount = by_days ? prorate(amount, ridden, days(from, @end)) : amount.round(2)
        notes << "Fees to #{pay_to.strftime('%d/%m/%Y')}#{by_days ? ", #{ridden} school days" : ', full period'}"
      end
      { rid: rider.rid, child_name: rider.name, amount:, note: notes.join(". ").presence,
        description: [ rider.name, fare[:tier], fare[:trip], fare[:bus].presence ].compact.join(" | ") }
    end

    def start_part(amount, ridden, total, day)
      case @rule
      when "full" then amount.round(2)
      when "half" then (day.day > 15 ? amount / 2 : amount).round(2)
      else prorate(amount, ridden, total)
      end
    end

    def start_note(half, ridden, total)
      case @rule
      when "full" then ", full period"
      when "half" then half ? ", half period" : ", full period"
      else ", #{ridden} of #{total} school days"
      end
    end

    def prorate(amount, ridden, total) = total.positive? ? (amount * [ ridden, total ].min / total).round(2) : amount.round(2)
    def days(from, to) = @year.school_days_between(from, to)

    def skip(text)
      @skipped << text
      nil
    end

    # ---- school pays per bus ----

    # Each bus size on the runs when the period starts (or the runs booked) × its rate with the Extra Charges, then what the
    # period really comes to (monthly bills: every run on every school day of the month with its route charge, spread over
    # the month's school days; one-off Extra Charges) as a line for route charges and changes during the period.
    def bus_bills
      rates = @table.bus_rates.to_a.select { it.rate.to_d.positive? }.index_by(&:bus_type)
      routes = SchoolRoute.joins(:plan).where(school_plans: { school_id: @school.id, in_use: true, session: %w[am pm] })
                          .where("school_plans.effective_from <= ? AND (school_plans.effective_to IS NULL OR school_plans.effective_to >= ?)", @end, @start)
                          .includes(:plan, :charges).to_a
      on = ->(d) { routes.select { |r| rates[r.bus_type] && r.plan.effective_from <= d && (r.plan.effective_to.nil? || r.plan.effective_to >= d) } }
      rate = ->(type) { FareTables.adjusted(rates[type].rate.to_d, @month, "bus:#{type}", @adjustments) }
      booked = @table.bus_count == "booked"
      counts = booked ? rates.transform_values { it.booked_runs.to_i }.select { |_, n| n.positive? } : on.(@start).map(&:bus_type).tally
      lines = counts.sort.map do |type, n|
        { rid: nil, child_name: nil, note: nil, description: "#{n} x #{type} at S$#{format('%.2f', rates[type].rate)}", amount: (n * rate.(type)).round(2) }
      end
      base = lines.sum(0.to_d) { it[:amount] }
      total = base + counts.sum(0.to_d) { |type, n| FareTables.one_offs(@month, "bus:#{type}", @adjustments) * n }
      days = @periods[@i][:school_days].to_i
      if @table.cycle == "month" && days.positive?
        total -= base unless booked
        (@month..@month.end_of_month).select { @year.school_day?(it) }.each do |d|
          on.(d).each do |r|
            c = RouteCharges.on(r, d)
            charge = c ? (c.kind == "pct" ? rates[r.bus_type].rate * c.value / 100 : c.value) : 0
            total += ((booked ? 0 : rate.(r.bus_type)) + charge) / days
          end
        end
      end
      extra = (total - base).round(2)
      lines << { rid: nil, child_name: nil, note: nil, description: "Route charges and changes during the period", amount: extra } if extra.abs > 0.005
      lines.empty? ? [] : [ bill("school", nil, lines) ]
    end
  end
end
