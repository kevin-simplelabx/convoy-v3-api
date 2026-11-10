# A child's fare row in a school's Bus Fares (shared by Family Bills and the Plan Estimate): the tier they fall in —
# straight-line km from the school, or the zone (postal sector or drawn area) of their home; the last tier otherwise —
# and the fare to take by the sessions they ride (2-way, 1-way, AM or PM, by the table's trip setting).
module FareTables
  module RiderFare
    module_function

    def tier_index(table, school, rider, tiers)
      if table.zones?
        sector = rider.postal.to_s[0, 2]
        z = tiers.index { |t| t.sectors.include?(sector) || (rider.lat && in_area?([ rider.lat.to_f, rider.lng.to_f ], t.areas)) }
        return z || (tiers.size - 1)
      end
      return tiers.size - 1 unless rider.lat && school.lat

      tiers.index { it.max_km && km(school, rider) <= it.max_km.to_f } || (tiers.size - 1)
    end

    def km(school, rider) = ((Geo.metres([ school.lat, school.lng ], [ rider.lat, rider.lng ]) / 1000.0) + 0.05).ceil(1)

    # The fare of a column (std, small, a size) for the sessions ("am" / "pm"): { periods: [...] } or nil.
    def pick(table, column, sessions)
      return nil unless column

      two = sessions.include?("am") && sessions.include?("pm")
      case table.trip
      when "one" then column[:one]
      when "ampm" then two ? column[:two] : column[sessions.include?("am") ? :am : :pm]
      else two ? column[:two] : (column[:one] || column[:two])
      end
    end

    # Inside a drawn outline of the zone and in none of its cut-outs (tiers need :areas preloaded).
    def in_area?(point, areas)
      add, sub = areas.partition { !it.exclude }
      add.any? { Geo.inside?(point, it.latlngs) } && sub.none? { Geo.inside?(point, it.latlngs) }
    end
  end
end
