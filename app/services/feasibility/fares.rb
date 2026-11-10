# Fare revenue of a scenario from the study's tiers (port of fzFare): students served (or all students before a run)
# counted per tier by straight-line km from the school (2-way for both sessions, 1-way otherwise), revenue, the fares
# that would reach the target (tier fares scaled together, or one flat fare), and the margin the current fares give.
module Feasibility
  module Fares
    DEFAULT_TIERS = [ 2, 4, 6, 8, 10, nil ].freeze

    module_function

    def call(study, sc, cost)
      place = study.place or return nil
      return nil unless cost

      tiers = study.fare_tiers.to_a.presence || DEFAULT_TIERS.map { FeasibilityFareTier.new(max_km: it) }
      geo = study.geocodes.select { |_, g| g.found }
      served = sc.result&.dig("sv")
      src = served.present? ? served.map { |k, n| pc, ses = k.split("|"); { postal: pc, session: ses, n: } } : study.rows.map { { postal: it.postal, session: it.session, n: it.riders } }
      rows = tiers.map { { n2: 0, n1: 0 } }
      src.each do |x|
        g = geo[x[:postal]] or next
        km = distance_km(place, g)
        i = tiers.each_index.find { |j| j < tiers.size - 1 && tiers[j].max_km && km <= tiers[j].max_km } || (tiers.size - 1)
        rows[i][x[:session] == "both" ? :n2 : :n1] += x[:n]
      end
      revenue = 0.to_d
      missing = false
      rows.each_with_index do |r, i|
        r[:n] = r[:n2] + r[:n1]
        r[:fare] = tiers[i].fare
        r[:one_way] = tiers[i].one_way_fare || tiers[i].fare
        missing = true if r[:n].positive? && r[:fare].nil?
        r[:revenue] = (r[:fare].to_d * r[:n2]) + (r[:one_way].to_d * r[:n1])
        revenue += r[:revenue]
        r[:max_km] = tiers[i].max_km
      end
      need = cost[:total] / (1 - cost[:margin])
      total = rows.sum { it[:n] }
      k = !missing && revenue.positive? ? need / revenue : nil
      flat = total.positive? ? need / total : nil
      rows.each do |r|
        r[:suggested] = k && r[:fare] ? (r[:fare] * k).ceil : flat&.ceil
        r[:suggested_one_way] = k && r[:one_way] ? (r[:one_way] * k).ceil : r[:suggested]
      end
      { tiers: rows, revenue: revenue.round(2), missing:, exact: served.present?, scaled: k.present?, students: total,
        fare_margin: revenue.positive? && !missing ? ((revenue - cost[:total]) / revenue).round(4) : nil }
    end

    # Straight-line km from the school, as bills count it (+0.05 km, rounded up to 0.1 km).
    def distance_km(place, g) = ((Geo.metres([ place[:lat], place[:lng] ], [ g.lat, g.lng ]) / 1000.0) + 0.05).ceil(1)
  end
end
