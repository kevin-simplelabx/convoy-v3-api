# School Dashboard › next 90 days (port of aheadVals), 8 each, soonest first. Operations: a plan to be adopted (its routes
# against the plan it replaces), a plan that stops running, riders starting and leaving. Finance: a plan to be adopted
# (operator cost a month, and revenue a month when the school pays per bus), route charges starting or ending, Extra
# Charges starting, a Payment & Refund Policy version starting.
module SchoolDashboard
  class Ahead
    DAYS = 90

    def initialize(school, today, year)
      @school = school
      @today = today
      @year = year
      @last = today + DAYS
    end

    def ops
      out = []
      adopting.each do |p, old|
        out << { date: p.effective_from, kind: "plan_adopted", title: "#{p.name} adopted as the #{p.session_name} plan",
                 routes: p.routes.size, replaces: old && { name: old.name, routes: old.routes.size } }
      end
      current.each do |p|
        out << { date: p.effective_to, kind: "plan_ends", title: "#{p.name} stops running" } if inside?(p.effective_to)
      end
      riders = SchoolRider.where(school: @school)
      riders.where(starts_on: (@today + 1)..@last).group(:starts_on).count.each do |d, n|
        out << { date: d, kind: "riders_start", title: "#{SchoolDashboard.plural(n, 'rider')} start", detail: "Check they have a stop and a route" }
      end
      riders.where(ends_on: (@today + 1)..@last).group(:ends_on).count.each do |d, n|
        out << { date: d, kind: "riders_leave", title: "#{SchoolDashboard.plural(n, 'rider')} leave" }
      end
      first(out)
    end

    def fin
      out = []
      table = @year&.fare_table
      bus_rates = table&.per_bus? && table.bus_count != "booked" ? table.bus_rates.index_by(&:bus_type) : nil
      adopting.each do |p, old|
        cost = SchoolPay::Cost.monthly(@school, p.routes, p.effective_from) - (old ? SchoolPay::Cost.monthly(@school, old.routes, p.effective_from) : 0)
        rev = bus_rates && (bus_total(p, bus_rates) - (old ? bus_total(old, bus_rates) : 0))
        out << { date: p.effective_from, kind: "plan_adopted", title: "#{p.name} adopted as the #{p.session_name} plan",
                 revenue_change: rev&.round(2), cost_change: cost.round(2) }
      end
      @school.route_charges.where(starts_on: (@today + 1)..@last).includes(:school_route).find_each do |c|
        out << { date: c.starts_on, kind: "route_charge", route: c.school_route&.label, title: c.value.to_d.zero? ? "Route charge ends" : (c.reason.presence || "Route charge"),
                 charge_kind: c.kind, value: c.value, note: c.note.presence }
      end
      if @year
        @school.fare_adjustments.where(academic_year: @year, from_month: (@today.beginning_of_month + 1.month)..@last).find_each do |a|
          out << { date: a.from_month, kind: "extra_charge", title: "#{a.name.presence || 'Extra charge'} starts", charge_kind: a.kind, value: a.value }
        end
      end
      @school.policy_versions.where(effective_on: (@today + 1)..@last).find_each do |v|
        out << { date: v.effective_on, kind: "policy", title: "Payment & Refund Policy version #{v.version} starts" }
      end
      first(out)
    end

    private

    def inside?(d) = d && d > @today && d <= @last
    def first(list) = list.sort_by { it[:date] }.first(8)

    def current = @current ||= SchoolDashboard.plans_on(@school, @today).includes(routes: :prices).to_a

    # Plans adopted from a day in the next 90 days, with the plan of the session running today.
    def adopting
      @adopting ||= @school.plans.where(in_use: true, effective_from: (@today + 1)..@last).includes(routes: %i[prices]).map do |p|
        [ p, current.find { it.session == p.session && it.id != p.id } ]
      end
    end

    def bus_total(plan, rates) = plan.routes.sum(0.to_d) { rates[it.bus_type]&.rate.to_d }
  end
end
