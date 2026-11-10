# The figures of the Dashboard widgets for a period (today, d7, d30, month = month to date, last_month), each compared
# with the period before (same day last week; the 7 / 30 days before; the same days last month; the month before).
# Widgets that look at "now" or ahead say so in `note`. Widgets without a data source yet answer available: false.
module Dashboard
  class Widgets
    PERIODS = %w[today d7 d30 month last_month].freeze
    HOURS_A_DAY = 12
    UNAVAILABLE = { "noshow" => "No-shows are not recorded yet" }.freeze

    def initialize(user:, period: "today", now: Time.current)
      @user = user
      @period = PERIODS.include?(period) ? period : "today"
      @now = now
      @today = now.to_date
      @company = ActsAsTenant.current_tenant
      @from, @to, @prev_from, @prev_to, @compare = range
    end

    def call(keys = nil)
      keys = Array(keys).presence || Catalogue::WIDGETS.keys
      list = keys.select { |k| Catalogue::WIDGETS.key?(k) && Catalogue.allowed?(@user, k) }
      { period: { key: @period, from: @from, to: @to, compare: @compare },
        widgets: list.index_with { |k| UNAVAILABLE[k] ? { available: false, reason: UNAVAILABLE[k] } : { available: true }.merge(send(k)) } }
    end

    private

    def range
      case @period
      when "d7" then [ @today - 6, @today, @today - 13, @today - 7, "the 7 days before" ]
      when "d30" then [ @today - 29, @today, @today - 59, @today - 30, "the 30 days before" ]
      when "month"
        start = @today.beginning_of_month
        [ start, @today, start.prev_month, [ start.prev_month + (@today.day - 1), start - 1 ].min, "the same days last month" ]
      when "last_month"
        start = @today.prev_month.beginning_of_month
        [ start, start.end_of_month, start.prev_month, start - 1, "the month before" ]
      else [ @today, @today, @today - 7, @today - 7, "same day last week" ]
      end
    end

    def runs(from = @from, to = @to) = TripOccurrence.visible.between(from, to)
    def allowance = @company.on_time_minutes
    def change(now, before) = now.nil? || before.nil? ? nil : (now - before).round(1)
    def pct(part, whole) = whole.positive? ? (part * 100.0 / whole).round(1) : nil

    # Runs that ran with a known lateness: on time when no stop was later than the company's allowance.
    def punctuality(from, to)
      known = runs(from, to).where(status: "completed").where.not(max_delay_minutes: nil)
      total = known.count
      on_time = known.where(max_delay_minutes: ..allowance).count
      { total:, on_time:, pct: pct(on_time, total) }
    end

    # ---- Operations -------------------------------------------------------------------------------------------------

    def otp
      now = punctuality(@from, @to)
      before = punctuality(@prev_from, @prev_to)
      series = (@from..@to).map { |d| { date: d, pct: punctuality(d, d)[:pct] } }
      { value: now[:pct], runs: now[:total], on_time: now[:on_time], change: change(now[:pct], before[:pct]), allowance:, series: }
    end

    def late
      list = runs.where(status: "completed").where("max_delay_minutes > ?", allowance).includes(:client, :vehicle).order(max_delay_minutes: :desc).limit(7)
      skipped = OccurrenceStopEvent.where(occurrence_date: @from..@to, skipped: true).count
      late_by_day = runs.where(status: "completed").where("max_delay_minutes > ?", allowance).group(:date).count
      missed_by_day = OccurrenceStopEvent.where(occurrence_date: @from..@to, skipped: true).group(:occurrence_date).count
      { count: runs.where(status: "completed").where("max_delay_minutes > ?", allowance).count, missed_pickups: skipped,
        series: (@from..@to).map { |d| { date: d, count: late_by_day[d].to_i + missed_by_day[d].to_i } },
        list: list.map { |o| { occurrence_id: o.id, date: o.date, trip_label: o.trip_label, client: o.client&.name, plate: o.vehicle&.plate, driver: o.driver_name, late_minutes: o.max_delay_minutes } } }
    end

    # Runs of the period: done / running now / still to run, the busiest day, by client and a count a day.
    def today
      counts = runs.group(:status).count
      before = runs(@prev_from, @prev_to).count
      total = counts.values.sum
      running = runs.where(status: "scheduled").where.not(started_at: nil).count
      by_day = runs.group(:date).count
      busiest = by_day.max_by { |d, n| [ n, d ] }
      by_client = runs.where.not(client_id: nil).group(:client_id).count
      names = Client.where(id: by_client.keys).pluck(:id, :name).to_h
      { total:, completed: counts["completed"].to_i, scheduled: counts["scheduled"].to_i, cancelled: counts["cancelled"].to_i, change: total - before,
        running:, still_to_run: counts["scheduled"].to_i - running, average_a_day: (total.to_f / ((@to - @from).to_i + 1)).round,
        busiest: busiest && { date: busiest[0], count: busiest[1] },
        by_client: by_client.map { |id, n| { client_id: id, name: names[id], runs: n } }.sort_by { -it[:runs] },
        series: (@from..@to).map { |d| { date: d, count: by_day[d].to_i } } }
    end

    # Runs in the next 7 days with no bus, or an own bus with no driver (an operator's bus brings its driver).
    def unas
      ahead = TripOccurrence.scheduled.between(@today, @today + 6).where("ends_at > ?", @now)
      scope = ahead.where(vehicle_id: nil).or(ahead.where(driver_id: nil, vehicle_id: Vehicle.own.select(:id)))
      { count: scope.count, note: "In the next 7 days. This does not follow the period",
        list: scope.includes(:client, :trip, school_route: :plan).chronological.limit(5).map do |o|
          { occurrence_id: o.id, date: o.date, start_time: Clock.hm(o.start_time), trip_label: o.trip_label, title: o.decorate.title, client: o.client&.name,
            missing: o.vehicle_id.nil? ? (o.driver_id.nil? ? "both" : "bus") : "driver" }
        end }
    end

    # Open Ops Control Alerts: trips flagged now (live, the period does not change it), most severe first.
    def alerts
      flagged = OpsControl::Sync.call(now: @now).select { it.severity.positive? }.sort_by { [ -it.severity, it.first_pickup_at ] }
      { count: flagged.size, action: flagged.count { it.severity == 2 }, at_risk: flagged.count { it.severity == 1 },
        note: "Live, so the period does not change it", period: alert_period,
        list: flagged.first(5).map do |c|
          { occurrence_id: c.occ.id, plate: c.occ.vehicle&.plate, title: c.occ.decorate.title, message: c.hits.first.message,
            severity: c.severity }
        end }
    end

    # Ops Control alerts raised in the period: how many, escalated, and the average time to acknowledge.
    def alert_period
      raised = OpsAlert.where(raised_at: @from.beginning_of_day..@to.end_of_day)
      ack = raised.where.not(acknowledged_at: nil).average(Arel.sql("EXTRACT(EPOCH FROM acknowledged_at - raised_at)"))
      { raised: raised.count, escalated: raised.where.not(escalated_at: nil).count, avg_ack_seconds: ack&.round }
    end

    def compl
      scope = runs.where.not(issue_raised_at: nil)
      { count: scope.count, change: scope.count - runs(@prev_from, @prev_to).where.not(issue_raised_at: nil).count,
        list: scope.order(issue_raised_at: :desc).limit(5).map { |o| { occurrence_id: o.id, date: o.date, trip_label: o.trip_label, reason: o.issue_reason } } }
    end

    # ---- Fleet and People -------------------------------------------------------------------------------------------

    # Hours on runs against hours available (12 a day per own vehicle).
    def util
      vehicles = Vehicle.kept.own.count
      now = utilisation(@from, @to, vehicles)
      { value: now, change: change(now, utilisation(@prev_from, @prev_to, vehicles)), vehicles:, hours_a_day: HOURS_A_DAY,
        series: (@from..@to).map { |d| { date: d, pct: utilisation(d, d, vehicles) } } }
    end

    def utilisation(from, to, vehicles)
      minutes = runs(from, to).where(vehicle_id: Vehicle.kept.own.select(:id)).where.not(status: "cancelled").sum("end_time - start_time")
      available = vehicles * HOURS_A_DAY * 60 * ((to - from).to_i + 1)
      pct(minutes, available)
    end

    def off
      repairs = MaintenanceVisit.scheduled.where(date: @today).includes(:vehicle)
      down = Replacement.where(kind: "veh").where("starts_on <= :d AND ends_on >= :d", d: @today).includes(:original_vehicle)
      # kind: the maintenance kind (Repair, Inspection…) or "Replaced"; back_on: the day it is expected back.
      list = repairs.map { |v| { vehicle_id: v.vehicle_id, plate: v.vehicle.plate, reason: "Maintenance: #{v.work_to_do || v.kind}", kind: v.kind_name, back_on: @today + 1 } } +
             down.map { |r| { vehicle_id: r.original_vehicle_id, plate: r.original_vehicle.plate, reason: "Vehicle down, replaced", kind: "Replaced", back_on: r.ends_on + 1 } }
      { count: list.uniq { |x| x[:vehicle_id] }.size, list: list.uniq { |x| x[:vehicle_id] }, note: "Shows today, so the period does not change it" }
    end

    def docs
      limit = @today + 60
      vehicles = Vehicle.kept.own.to_a
      list = vehicles.flat_map do |v|
        [ [ "COE", v.coe_expires_on ], [ "Road Tax", v.road_tax_expires_on ] ].filter_map do |kind, date|
          { vehicle_id: v.id, plate: v.plate, document: kind, expires_on: date } if date && date <= limit
        end
      end
      VehicleInsurancePolicy.where(vehicle_id: vehicles.map(&:id), ends_on: ..limit).includes(:vehicle).find_each do |p|
        next if VehicleInsurancePolicy.where(vehicle_id: p.vehicle_id).where("starts_on > ?", p.ends_on).exists?

        list << { vehicle_id: p.vehicle_id, plate: p.vehicle.plate, document: "Insurance", expires_on: p.ends_on }
      end
      list.sort_by! { |x| x[:expires_on] }
      { count: list.size, expired: list.count { |x| x[:expires_on] < @today }, list: list.first(8), note: "Looks ahead 60 days, so the period does not change it" }
    end

    def duty
      active = Driver.kept.active.count
      driving = TripOccurrence.visible.on(@today).where.not(driver_id: nil).where.not(status: "cancelled").distinct.count(:driver_id)
      on_bus = VehicleDriverSchedule.current_on(@today).where.not(driver_id: nil).distinct.count(:driver_id)
      { active:, driving_today: driving, without_bus: [ active - on_bus, 0 ].max, pending_invites: Driver.kept.where(status: "pending").count,
        note: "Shows today, so the period does not change it" }
    end

    # ---- Money ------------------------------------------------------------------------------------------------------

    def rev
      now = runs.where.not(status: "cancelled").sum(:price)
      before = runs(@prev_from, @prev_to).where.not(status: "cancelled").sum(:price)
      { value: now, change: (now - before).round(2), change_pct: before.positive? ? ((now - before) * 100 / before).round(1) : nil,
        series: runs.where.not(status: "cancelled").group(:date).sum(:price).sort.map { |d, v| { date: d, amount: v } },
        month: (fleet_month.then { { revenue: it[:revenue], cost: it[:cost], profit: it[:profit] } } if Catalogue.allowed?(@user, "profit")) }
    end

    def fleet_month = @fleet_month ||= Finance::VehicleReport.new(period: "month", month: @today).fleet

    # This month's fleet profit, the change on last month, the year to date (chart months of this year) and by vehicle.
    def profit
      fleet = fleet_month
      last = fleet[:chart][-2]
      ytd = fleet[:chart].select { it[:month].start_with?(@today.year.to_s) }.sum(0.to_d) { it[:profit] }
      { revenue: fleet[:revenue], cost: fleet[:cost], profit: fleet[:profit], margin: fleet[:margin], chart: fleet[:chart],
        change: last && (fleet[:profit] - last[:profit]).round(2), ytd:,
        vehicles: fleet[:vehicles].reverse.map { it.slice(:vehicle_id, :plate, :profit) }, note: "This month, so the period does not change it" }
    end

    def topbot
      now = fleet_month[:vehicles]
      before = Finance::VehicleReport.new(period: "month", month: @today.prev_month).fleet[:vehicles].to_h { |v| [ v[:vehicle_id], v[:profit] ] }
      rows = now.map { |v| v.slice(:vehicle_id, :plate, :profit).merge(change: before[v[:vehicle_id]] ? v[:profit] - before[v[:vehicle_id]] : nil) }
      { top: rows.last(5).reverse, bottom: rows.size > 5 ? rows.first(5) : [], note: "This month, so the period does not change it" }
    end

    def opp
      items = OperatorPay::Due.call
      ready = items.select(&:ready)
      unpaid = OperatorPayBatch.includes(batch_operators: %i[lines payments]).to_a.reject { |b| b.status == "paid" }
      nxt = unpaid.min_by(&:pay_date)
      { waiting: ready.sum(0.to_d) { |i| i.amount.to_d }, waiting_items: ready.size, waiting_operators: ready.map(&:operator).uniq.size,
        approved_unpaid: unpaid.sum(0.to_d) { |b| b.total - b.paid }, approved_unpaid_batches: unpaid.size,
        next_pay: nxt && { date: nxt.pay_date, number: nxt.number, amount: nxt.total - nxt.paid }, note: "Current balances, so the period does not change them" }
    end

    # School Bus bills of the schools the user may open (Finance › School Bus Collections), as of today.
    def coll
      SchoolBills::Company.call(Pundit.policy_scope!(@user, School), today: @today)[:kpis]
                          .merge(note: "Current balances, so the period does not change them")
    end

    def loans
      month = @today.beginning_of_month
      rows = VehicleFinancial.funded_by_loan.includes(:payments, :vehicle).flat_map do |f|
        f.schedule(@today).rows.select { |r| r.paid_on.nil? && (r.status == "overdue" || r.due_on.beginning_of_month == month) }
         .map { |r| { vehicle_id: f.vehicle_id, plate: f.vehicle.plate, lender: f.lender, due_on: r.due_on, amount: r.amount, overdue: r.status == "overdue" } }
      end.sort_by { |r| r[:due_on] }
      { due: rows.sum(0.to_d) { |r| r[:amount] }, count: rows.size, overdue: rows.count { |r| r[:overdue] },
        overdue_amount: rows.select { |r| r[:overdue] }.sum(0.to_d) { |r| r[:amount] }, list: rows.first(6), note: "This month, so the period does not change it" }
    end

    # ---- Clients ----------------------------------------------------------------------------------------------------

    # On time by client in the period, and the change in points on the period before.
    def clotp
      @clotp ||= begin
        now = client_punctuality(@from, @to)
        before = client_punctuality(@prev_from, @prev_to)
        names = Client.where(id: now.keys).pluck(:id, :name).to_h
        { target: 95, clients: now.map { |id, (n, p)| { client_id: id, name: names[id], runs: n, on_time: p, change: change(p, before[id]&.last) } }.sort_by { |c| -c[:runs] } }
      end
    end

    def client_punctuality(from, to)
      known = runs(from, to).where(status: "completed").where.not(max_delay_minutes: nil).where.not(client_id: nil)
      on_time = known.where(max_delay_minutes: ..allowance).group(:client_id).count
      known.group(:client_id).count.to_h { |id, n| [ id, [ n, pct(on_time[id].to_i, n) ] ] }
    end

    # Clients below 95 % on time in the period, falling a point or more on the period before, or with overdue invoices.
    def clrisk
      late = clotp[:clients].select { |c| c[:on_time] && (c[:on_time] < 95 || c[:change].to_f <= -1) }
      overdue = ClientInvoice.invoice.issued.where(due_on: ...@today).includes(:client, :payments, :credit_notes).select { |i| i.balance > 0.005 }
                             .group_by(&:client).transform_values { |l| l.sum(&:balance) }
      ids = (late.map { |c| c[:client_id] } + overdue.keys.map(&:id)).uniq
      clients = Client.where(id: ids).index_by(&:id)
      list = ids.map do |id|
        reasons = []
        (c = late.find { |x| x[:client_id] == id }) && reasons << "On time #{c[:on_time]}%#{" (#{format('%+.1f', c[:change])} pts)" if c[:change]}"
        (o = overdue.find { |cl, _| cl.id == id }) && reasons << "S$#{format('%.2f', o[1])} overdue"
        { client_id: id, name: clients[id]&.name, reasons:, on_time: c&.dig(:on_time), change: c&.dig(:change),
          badge: c && c[:on_time] < 95 ? "Below Target" : (c ? "Falling" : "Overdue") }
      end
      { count: list.size, list: }
    end
  end
end
