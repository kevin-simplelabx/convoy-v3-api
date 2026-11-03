# What a scenario costs a month (port of fzCost): each session's buses by size (plus buffer buses) at the study's price,
# attendants at their add-on, the largest session's buses, break-even per student served, and the fare per student
# for the margin. missing = sizes with no price.
module Feasibility
  module Cost
    module_function

    def call(study, sc)
      res = sc.result or return nil
      prices = study.bus_prices.index_by(&:bus_type)
      extra = sc.extra_buses.presence || {}
      cost = 0.to_d
      ba_cost = 0.to_d
      missing = []
      by = %w[AM PM].to_h do |se|
        routes = res.dig(se, "routes")
        cnt = Hash.new(0)
        ba = Hash.new(0)
        xb = {}
        Array(routes).each do |r|
          cnt[r["type"]] += 1
          ba[r["type"]] += 1 if r["attendant"]
        end
        (extra[se] || {}).each do |t, n|
          n = n.to_i
          next unless routes && n.positive?

          xb[t] = n
          cnt[t] += n
          ba[t] += n if sc.attendant == "ALL_BUSES"
        end
        cnt.each do |t, n|
          p = prices[t]
          p&.monthly ? cost += p.monthly * n : (missing << t unless missing.include?(t))
          ba_cost += p.attendant * ba[t] if p&.attendant && ba[t].positive?
        end
        [ se, { on: routes.present?, buses: cnt, attendants: ba, buffer: xb, n: cnt.values.sum, buffer_n: xb.values.sum } ]
      end
      total = cost + ba_cost
      served = res["served"].to_i
      m = sc.margin_pct.to_d.clamp(0, 90) / 100
      { by_session: by, buses: [ by["AM"][:n], by["PM"][:n] ].max, runs: by["AM"][:n] + by["PM"][:n], buffer: by["AM"][:buffer_n] + by["PM"][:buffer_n],
        total: total.round(2), attendant_cost: ba_cost.round(2), missing:, served:, margin: m,
        break_even: served.positive? ? (total / served).round(2) : nil, target_fare: served.positive? ? (total / (1 - m) / served).round(2) : nil }
    end
  end
end
