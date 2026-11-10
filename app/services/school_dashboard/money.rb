# School Dashboard › Finance (port of dashVals' finance half + dashRev): a month's state (closed, in progress, forecast),
# KPIs — revenue expected (each billing period's fares, as Family Bills would draft them for every rider, times the
# share of its school days in the month; all of a monthly bill), operator cost (School Finance › Operator Payments),
# operating profit and margin, cost per rider, riders and seat use on the month's reference day — Expected / Billed /
# Collected, overdue bills, the academic year by month (revenue against cost), money changes in the next 90 days and
# what needs attention (bus sizes without a school rate, more runs than booked, route charges to check, money setup
# steps, routes not priced).
module SchoolDashboard
  class Money
    SETUP = %w[fares policy operator_pay].freeze

    def initialize(school, month, today: Date.current)
      @school = school
      @month = month.beginning_of_month
      @today = today
      @drafts = {}
      @periods = {}
    end

    def call
      year = year_of(@month + 14)
      day = ref_day(@month, year)
      rev = revenue(@month)
      cost = SchoolPay::Cost.call(@school, @month)
      riders = SchoolDashboard.riders_on(@school, day).size
      load, seats, routes = seat_use(day)
      exp = rev[:error] ? nil : rev[:expected]
      profit = exp && (exp - cost[:total]).round(2)
      { month: ym(@month), state:, reference_day: day, paid_month: cost[:paid_month],
        kpis: { revenue: exp, revenue_note: rev[:error], revenue_basis: rev[:basis], revenue_riders: rev[:riders], academic_year: rev[:key],
                operator_cost: cost[:total].round(2), profit:, margin_pct: exp&.positive? ? (profit * 100 / exp).round(1).to_f : nil,
                cost_per_rider: riders.positive? ? (cost[:total] / riders).round(2) : nil, riders:,
                seats: { riders: load, seats:, routes:, pct: seats.positive? ? (load * 100.0 / seats).round(1) : nil } },
        collections: collections(rev), route_costs: route_costs(cost), year: year_chart(year), ahead: Ahead.new(@school, @today, SchoolDashboard.year_on(@school, @today)).fin,
        attention: attention(year, cost) }
    end

    private

    def ym(date) = date.strftime("%Y-%m")

    def state
      cur = @today.beginning_of_month
      return "closed" if @month < cur

      @month == cur ? "in_progress" : "forecast"
    end

    # The day riders and seats are counted on: today in this month, else the month's first school day, else the 15th.
    def ref_day(month, year)
      return @today if month == @today.beginning_of_month

      (month..month.end_of_month).find { year&.school_day?(it) } || (month + 14)
    end

    # Revenue expected in a month: { expected, billable (the bills of the periods billed in the month, in full: "Expected
    # bills: S$x. Not raised yet"), riders, key } or { error }.
    def revenue(month)
      year = year_of(month + 14)
      return { error: "No academic year covers #{month.strftime('%b %Y')}" } unless year

      table = year.fare_table
      return { error: "Bus Fares for AY #{year.key} not saved yet" } unless table&.locked?

      periods, bill_months = @periods[year.id] ||= [ FareTables.periods(year, table), FareTables.bill_months(year, table) ]
      expected = 0.to_d
      billable = 0.to_d
      riders = Set.new
      periods.each_with_index do |p, i|
        if bill_months[i] == month
          d = draft(year, i)
          billable += d[:bills].sum(0.to_d) { it[:amount] } unless d[:error]
        end
        share = if table.cycle == "month" then bill_months[i] == month ? 1 : 0
        else
                  days = p[:school_days].to_i
                  inside = [ p[:starts_on], month ].compact.max..[ p[:ends_on], month.end_of_month ].compact.min
                  days.positive? && inside.first <= inside.last ? year.school_days_between(inside.first, inside.last).to_d / days : 0
        end
        next unless share.positive?

        d = draft(year, i)
        next if d[:error]

        expected += d[:bills].sum(0.to_d) { it[:amount] } * share
        d[:bills].each { |b| b[:lines].each { riders << it[:rid] if it[:rid] } }
      end
      { expected: expected.round(2), billable: billable.round(2), riders: riders.size, key: year.key, basis: table.per_bus? ? "bus" : "rider" }
    end

    def year_of(day)
      @years ||= @school.academic_years.includes(:terms, :holidays, :setup_locks, fare_table: :academic_year).to_a
      @years.find { it.starts_on <= day && day <= it.ends_on }
    end

    def draft(year, i) = @drafts[[ year.id, i ]] ||= SchoolBills::Draft.call(year, i, expected: true)

    def seat_use(day)
      routes = SchoolRoute.joins(:plan).merge(SchoolDashboard.plans_on(@school, day)).pluck(:riders_count, :student_seats)
      [ routes.sum { it[0].to_i }, routes.sum { it[1].to_i }, routes.size ]
    end

    # Expected / Billed (bills raised for the month) / Collected (payments in the month) and the bills overdue today.
    def collections(rev)
      bills = SchoolBill.issued.where(school: @school, billing_month: @month)
      paid = SchoolBillPayment.joins(:school_bill).where(school_bills: { school_id: @school.id }, voided_at: nil, paid_on: @month..@month.end_of_month)
      over = SchoolBills::Collections.call(@school, today: @today)[:rows].select(&:overdue)
      { expected: rev[:error] ? nil : rev[:expected], billable: rev[:billable], billed: bills.sum(:total).to_d.round(2), bills: bills.count,
        collected: paid.sum(:amount).to_d.round(2), overdue: { bills: over.size, owed: over.sum(0.to_d, &:owed).round(2) } }
    end

    # Finance › Route Costs: each route's cost this month (operator, price, days run) and the total by transport operator.
    def route_costs(cost)
      name = ->(key, op) { op&.name || (key == "own" ? "Our buses" : "Not assigned") }
      { total: cost[:total].round(2), school_days: cost[:school_days], priced: cost[:priced], routes: cost[:routes],
        rows: cost[:rows].map do |r|
          { route: r.route.label, session: r.plan.session, plan: r.plan.name, bus_type: (size = r.route.bus_size(r.vehicle)), bus_type_label: size && SchoolBus.label(size), plate: r.vehicle&.plate,
            operator: name.(r.key.to_s, r.operator), price: r.price, unpriced: r.unpriced, days: r.days, of: r.of, amount: r.amount, note: r.note,
            attendant: r.attendant }
        end,
        by_operator: cost[:by_operator].map { |key, v| { key: key.to_s, operator_id: v[:operator]&.id, name: name.(key.to_s, v[:operator]), routes: v[:routes], amount: v[:amount].round(2) } }
                                       .sort_by { -it[:amount] } }
    end

    # The academic year's 12 months: revenue expected and operator cost.
    def year_chart(year)
      return [] unless year

      (0..11).map do |i|
        m = year.starts_on.beginning_of_month >> i
        r = revenue(m)
        c = SchoolPay::Cost.call(@school, m)[:total].round(2)
        rv = r[:error] ? 0.to_d : r[:expected]
        { month: ym(m), revenue: rv, cost: c, profit: (rv - c).round(2) }
      end
    end

    def attention(year, cost)
      out = []
      table = year&.fare_table
      if table&.locked? && table.per_bus?
        rates = table.bus_rates.to_a.index_by(&:bus_type)
        planned = SchoolRoute.joins(:plan).merge(SchoolDashboard.plans_on(@school, @today)).where.not(bus_type: nil).group(:bus_type).count
        none = planned.keys.reject { rates[it]&.rate.to_d.positive? }
        if none.any?
          out << { kind: "bus_rates", title: "#{SchoolDashboard.plural(none.size, 'bus size')} with no school rate",
                   detail: "#{none.join(', ')} in the route plans but not on the school bill" }
        end
        if table.bus_count == "booked"
          over = planned.select { |t, n| n > rates[t]&.booked_runs.to_i }
          if over.any?
            out << { kind: "booked_runs", title: "Route plans have more runs than booked",
                     detail: over.map { |t, n| "#{t}: #{n} planned, #{rates[t]&.booked_runs.to_i} booked" }.join(" | ") }
          end
        end
      end
      check = @school.route_charges.where(status: "check").count
      if check.positive?
        out << { kind: "route_charges", title: "#{SchoolDashboard.plural(check, 'route charge')} to check",
                 detail: "Moved to a new route plan. An Admin confirms the matched run in Bus Fares" }
      end
      if year
        todo = SchoolSetup::Steps.new(year).call[:steps].select { SETUP.include?(it[:key]) && !it[:done] }
        out << { kind: "setup", title: "#{SchoolDashboard.plural(todo.size, 'setup step')} not done", detail: todo.map { it[:label] }.join(", ") } if todo.any?
      end
      unpriced = cost[:routes] - cost[:priced]
      out << { kind: "unpriced", title: "#{SchoolDashboard.plural(unpriced, 'route')} not priced", detail: "Set a default price per bus size in Operator Pay" } if unpriced.positive?
      out
    end
  end
end
