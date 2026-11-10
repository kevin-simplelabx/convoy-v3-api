# Vehicle Financials > profit and loss views from Finance::VehiclePl: a period (month, year to date, this year, last
# year, last 12 months, all time) on the profit or cash basis — fleet totals, by vehicle, by category, the 12-month
# chart; a vehicle's view with break-even; cost per km by bus size; cost spikes; what is due in the next 90 days.
module Finance
  class VehicleReport
    PERIODS = %w[month ytd this_year last_year last_12 all].freeze
    SIZES = [ [ "Minibus", ..13 ], [ "Medium Bus", 14..29 ], [ "Coach", 30.. ] ].freeze

    def initialize(period: "month", basis: "profit", month: Date.current, today: Date.current, vehicles: nil)
      @period = PERIODS.include?(period) ? period : "month"
      @basis = basis == "cash" ? "cash" : "profit"
      @month = month.beginning_of_month
      @today = today
      @vehicles = (vehicles || Vehicle.kept.own.order(:plate)).to_a
      @from, @to = range
    end

    def fleet
      pl = lines(@from, @to)
      series = chart(nil)
      runs = billed_runs.group(:vehicle_id).count
      by_vehicle = @vehicles.map do |v|
        rev, cost = totals(pl[v.id].values.flatten)
        { vehicle_id: v.id, plate: v.plate, seats: v.seats, revenue: rev, cost:, profit: rev - cost, break_even: break_even(pl[v.id], runs[v.id].to_i),
          categories: categories(pl[v.id].values.flatten, tree: false) }
      end
      rev, cost = totals(pl.values.flat_map { |m| m.values.flatten })
      { period: @period, basis: @basis, from: @from, to: @to, revenue: rev, cost:, profit: rev - cost,
        margin: rev.positive? ? ((rev - cost) / rev * 100).round(1) : nil, vehicles: by_vehicle.sort_by { |r| r[:profit] },
        categories: categories(pl.values.flat_map { |m| m.values.flatten }), chart: series, running_total: running_total(series),
        cost_per_km: cost_per_km(pl) }
    end

    def vehicle(v)
      pl = lines(@from, @to)[v.id]
      rev, cost = totals(pl.values.flatten)
      series = chart(v.id)
      { vehicle_id: v.id, plate: v.plate, period: @period, basis: @basis, from: @from, to: @to, revenue: rev, cost:, profit: rev - cost,
        categories: categories(pl.values.flatten), chart: series, running_total: running_total(series), break_even: break_even(pl, billed_runs.where(vehicle_id: v.id).count) }
    end

    # Cost items this month above 1.5 × the median of the six months before (with that cost in 3 of them) and S$100 over it.
    def spikes
      start = @month << 6
      pl = lines(start, @month.end_of_month)
      acks = VehicleCostSpikeAck.where(month: @month).pluck(:vehicle_id, :category).to_set
      @vehicles.flat_map do |v|
        months = pl[v.id]
        now = sums(months[@month])
        now.filter_map do |cat, amount|
          next if %w[Purchase Down\ Payment].include?(cat)

          before = (1..6).map { |i| sums(months[@month << i])[cat] }.compact
          next if before.size < 3

          median = before.sort[before.size / 2]
          next unless amount > median * 1.5 && amount - median >= 100

          { vehicle_id: v.id, plate: v.plate, category: cat, amount:, usual: median, month: @month, checked: acks.include?([ v.id, cat ]) }
        end
      end
    end

    # Unpaid instalments up to 90 days ahead (and overdue), insurance renewals, road tax and COE expiry.
    def due
      limit = @today + 90
      @vehicles.flat_map do |v|
        f = v.financial
        rows = f ? f.schedule(@today).rows.select { |r| r.paid_on.nil? && r.due_on <= limit } : []
        list = rows.map { |r| { vehicle_id: v.id, plate: v.plate, date: r.due_on, kind: "instalment", text: "Instalment #{r.n}#{r.status == 'overdue' ? ' (overdue)' : ''}", amount: r.amount } }
        policy = VehicleInsurancePolicy.where(vehicle_id: v.id).where(ends_on: ..limit).order(:ends_on).last
        list << { vehicle_id: v.id, plate: v.plate, date: policy.ends_on, kind: "insurance", text: "Renew insurance", amount: policy.total || policy.premium } if policy && policy.ends_on >= @today - 30
        if v.road_tax_expires_on && v.road_tax_expires_on <= limit
          tax = v.finance_entries.where(category: "Road Tax").order(:entry_on).last
          list << { vehicle_id: v.id, plate: v.plate, date: v.road_tax_expires_on, kind: "road_tax", text: "Road tax", amount: tax && (tax.repeats_monthly ? tax.amount * 12 : tax.amount) }
        end
        list << { vehicle_id: v.id, plate: v.plate, date: v.coe_expires_on, kind: "coe", text: "COE expires: renew or deregister", amount: nil } if v.coe_expires_on && v.coe_expires_on <= limit
        list
      end.sort_by { |r| r[:date] }
    end

    private

    def range
      case @period
      when "ytd" then [ @today.beginning_of_year, @today ]
      when "this_year" then [ @today.beginning_of_year, @today.end_of_year ]
      when "last_year" then [ @today.prev_year.beginning_of_year, @today.prev_year.end_of_year ]
      when "last_12" then [ @today.beginning_of_month << 11, @today ]
      when "all" then [ history_start, @today ]
      else [ @month, @month.end_of_month ]
      end
    end

    # The first month on record: the earliest purchase, at most 36 months back.
    def history_start = [ VehicleFinancial.minimum(:bought_on), @today.beginning_of_month << 35 ].compact.min

    def lines(from, to) = Finance::VehiclePl.call(vehicles: @vehicles, from:, to:, basis: @basis, today: @today)

    def totals(list) = [ list.select { |l| l[:kind] == "revenue" }.sum(0.to_d) { |l| l[:amount] }, list.select { |l| l[:kind] == "cost" }.sum(0.to_d) { |l| l[:amount] } ]

    def sums(list) = list.select { |l| l[:kind] == "cost" }.group_by { |l| l[:category] }.transform_values { |x| x.sum(0.to_d) { |l| l[:amount] } }

    # By category, biggest first; with tree: the dive under each (children → children), biggest first, as the prototype.
    def categories(list, tree: true)
      list.group_by { |l| [ l[:kind], l[:category] ] }.map do |(kind, cat), x|
        row = { kind:, category: cat, amount: x.sum(0.to_d) { |l| l[:amount] } }
        tree ? row.merge(children: branch(x.select { it[:path] }, 0)) : row
      end.sort_by { |c| [ c[:kind] == "revenue" ? 0 : 1, -c[:amount] ] }
    end

    def branch(list, level)
      return [] if level > 1

      list.select { it[:path][level] }.group_by { it[:path][level] }.map do |name, x|
        { name:, amount: x.sum(0.to_d) { |l| l[:amount] } }.merge(level.zero? ? { children: branch(x, 1) } : {})
      end.sort_by { -it[:amount] }
    end

    # The 12 months to the selected month: revenue, cost, profit and the running total (profit from the first month on record
    # to the end of that month, as the prototype's "Running Total"), for one vehicle or the fleet.
    def chart(vehicle_id)
      window = @month << 11
      first = [ window, history_start.beginning_of_month ].min
      pl = lines(first, @month.end_of_month)
      run = 0.to_d
      rows = (0..((@month.year * 12 + @month.month) - (first.year * 12 + first.month))).map do |i|
        m = first >> i
        list = vehicle_id ? pl[vehicle_id][m] : pl.values.flat_map { |x| x[m] }
        rev, cost = totals(list)
        { month: m.strftime("%Y-%m"), revenue: rev, cost:, profit: rev - cost, running_total: (run += rev - cost) }
      end
      rows.last(12)
    end

    # The Month period's "Running Total" card: profit to the end of the selected month; other periods have none.
    def running_total(series) = @period == "month" ? series.last[:running_total] : nil

    # Runs done in the period (up to today) with a client price.
    def billed_runs = TripOccurrence.between(@from, [ @to, @today ].min).where.not(status: %w[cancelled removed skipped]).where("price > 0")

    # Runs needed at this period's average trip price to cover the cost not covered by other revenue (none below 0).
    def break_even(pl, runs)
      list = pl.values.flatten
      rev, cost = totals(list)
      trip_rev = list.select { |l| l[:kind] == "revenue" && l[:category].end_with?("(auto)") }.sum(0.to_d) { |l| l[:amount] }
      per = runs.positive? ? (trip_rev / runs).round(2) : nil
      need = per&.positive? ? [ ((cost - (rev - trip_rev)) / per).ceil, 0 ].max : nil
      { revenue: rev, cost:, trip_revenue: trip_rev, runs:, per_run: per, runs_needed: need, gap: cost - rev }
    end

    # Cost, revenue and profit per km by bus size (km from Fuel & Energy odometer readings in the period).
    def cost_per_km(pl)
      km = FuelEntry.where(vehicle_id: @vehicles.map(&:id), date: @from..@to).group(:vehicle_id).sum(:km_since)
      SIZES.map do |label, seats|
        list = @vehicles.select { |v| v.seats && seats.cover?(v.seats) }
        k = list.sum { |v| km[v.id].to_i }
        rev, cost = totals(list.flat_map { |v| pl[v.id].values.flatten })
        { size: label, vehicles: list.size, km: k, cost_per_km: k.positive? ? (cost / k).round(2) : nil,
          revenue_per_km: k.positive? ? (rev / k).round(2) : nil, profit_per_km: k.positive? ? ((rev - cost) / k).round(2) : nil }
      end
    end
  end
end
