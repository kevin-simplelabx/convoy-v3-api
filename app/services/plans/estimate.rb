# A route plan's money for a month (port of Convoy OS planMoney / planCost; finance or finview): the operator cost of its
# routes for the whole month (routes not priced counted), and — when the school's parents or the school pay per rider —
# the revenue of the plan's riders: each one's yearly fare (tier by distance or zone; one-way or two-way by the AM / PM
# in the rider data) over 12, plus the month's one-off charges; To Collect = what is billed in the month. Two-way riders
# count half (the other half is on the plan of the other session). By band, the profit and loss and the notes.
module Plans
  class Estimate < ApplicationService
    def initialize(plan, month:)
      @plan = plan
      @school = plan.school
      @month = month.beginning_of_month
    end

    def call
      title = "Estimate for #{label}"
      pay = @school.operator_pay || SchoolOperatorPay.new(school: @school)
      unless pay.rate(@month.month).positive?
        return { month: @month, title:, sub: "#{@plan.name} | #{label}", paid_month: false, note: "#{label} is not a paid month" }
      end

      cost = SchoolPay::Cost.for_plan(@plan, @month)
      total = cost[:total].round(2)
      unpriced = cost[:rows].count(&:unpriced)
      riders = plan_riders
      rev = revenue(riders)
      notes = []
      notes << "#{unpriced} route#{'s' unless unpriced == 1} not priced, so cost is low" if unpriced.positive?
      out = { month: @month, title:, sub: "#{@plan.name} | #{label}", paid_month: true, riders: riders.size, operator_cost: total, unpriced:,
              routes: cost[:rows].map { |r| { route_id: r.route.id, label: r.route.label, bus_type: r.route.bus_type, amount: r.unpriced ? nil : r.amount } } }
      if rev[:none]
        notes << rev[:none]
        return out.merge(revenue: nil, revenue_none: rev[:none], to_collect: nil, gross_profit: nil, margin_pct: nil, notes:)
      end

      gp = (rev[:revenue] - total).round(2)
      notes << "Revenue is a year of fares spread over 12 months. To Collect is what is billed in #{label}" \
               "#{', when a term starts' unless rev[:cycle] == 'month'}#{'. Two-way riders count half here, half in the other session' if rev[:two].positive?}"
      out.merge(revenue: rev[:revenue], to_collect: rev[:to_collect], gross_profit: gp, margin_pct: rev[:revenue].positive? ? (gp * 100 / rev[:revenue]).round(1).to_f : nil,
                basis: rev[:basis], bands: rev[:bands], two_way: rev[:two], no_fare: rev[:no_fare],
                pl: { one_way: { riders: rev[:n1], amount: rev[:e1] }, two_way: { riders: rev[:n2], total: rev[:e2], half: (rev[:e2] / 2).round(2) } }, notes:)
    end

    private

    def label = @month.strftime("%b %Y")

    # The plan's riders on the rider list, two-way when the rider data has both AM and PM.
    def plan_riders
      rids = SchoolRouteRider.where(school_route_id: @plan.routes.select(:id)).distinct.pluck(:rid)
      day = [ @month + 14, @plan.effective_from ].max
      SchoolRider.of_school_on(@school, day).where(rid: rids).map do |r|
        sessions = [ ("am" if r.am), ("pm" if r.pm) ].compact.to_set << @plan.session
        { rider: r, sessions:, two: sessions.include?("am") && sessions.include?("pm") }
      end
    end

    def revenue(riders)
      year = @school.academic_years.covering(@month + 14).first
      return { none: "No academic year covers #{label}" } unless year

      table = year.fare_table
      return { none: "Bus Fares for AY #{year.key} not saved yet" } unless table&.locked?
      return { none: "School is billed per bus for the whole fleet, so revenue is on the Dashboard" } if table.per_bus?

      periods = FareTables.periods(year, table)
      bill_months = FareTables.bill_months(year, table)
      fares = FareTables::Calc.call(table, periods)
      tiers = table.tiers.includes(:areas).to_a
      adjustments = @school.fare_adjustments.where(academic_year: year).includes(:targets).to_a
      bands = tiers.each_with_index.map { |t, i| { label: fares.dig(i, :label) || "#{table.zones? ? 'Zone' : 'Band'} #{i + 1}", tier_id: t.id, riders: 0, one_way: 0, two_way: 0, revenue: 0.to_d, to_collect: 0.to_d } }
      none = { label: "No fare set", riders: 0, one_way: 0, two_way: 0, revenue: 0.to_d, to_collect: 0.to_d, no_fare: true }
      sums = { e1: 0.to_d, e2: 0.to_d, b1: 0.to_d, b2: 0.to_d, n1: 0, n2: 0 }
      riders.each do |x|
        ti = FareTables::RiderFare.tier_index(table, @school, x[:rider], tiers)
        fare = FareTables::RiderFare.pick(table, fares.dig(ti, :std), x[:sessions])
        band = fare ? bands[ti] : none
        w = x[:two] ? 0.5 : 1
        band[:riders] += 1
        band[x[:two] ? :two_way : :one_way] += 1
        next unless fare

        tier = tiers[ti]
        yearly = fare[:periods].each_with_index.sum(0.to_d) { |a, i| FareTables.adjusted(a.to_d, bill_months[i], tier.id, adjustments) }
        billed = fare[:periods].each_with_index.sum(0.to_d) { |a, i| bill_months[i] == @month ? FareTables.adjusted(a.to_d, bill_months[i], tier.id, adjustments) : 0 }
        once = FareTables.one_offs(@month, tier.id, adjustments)
        e = (yearly / 12) + once
        b = billed + once
        band[:revenue] += e * w
        band[:to_collect] += b * w
        k = x[:two] ? 2 : 1
        sums[:"e#{k}"] += e
        sums[:"b#{k}"] += b
        sums[:"n#{k}"] += 1
      end
      all = bands + (none[:riders].positive? ? [ none ] : [])
      total = riders.size
      { revenue: (sums[:e1] + (sums[:e2] / 2)).round(2), to_collect: (sums[:b1] + (sums[:b2] / 2)).round(2), cycle: table.cycle,
        basis: table.zones? ? "zone" : "distance", two: riders.count { it[:two] }, no_fare: none[:riders],
        e1: sums[:e1].round(2), e2: sums[:e2].round(2), n1: sums[:n1], n2: sums[:n2],
        bands: all.map { it.merge(share: total.positive? ? (it[:riders] * 100.0 / total).round(1) : 0.0, revenue: it[:revenue].round(2), to_collect: it[:to_collect].round(2)) } }
    end
  end
end
