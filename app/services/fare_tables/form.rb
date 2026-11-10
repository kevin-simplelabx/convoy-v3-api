# The Bus Fares wizard's table as sent (PUT /academic_years/:id/fares, POST …/fares/preview), cleaned for Save and the
# draft preview: postal sectors as 2-digit lists, drawn areas as [{ exclude, latlngs: [[lat, lng], …] }], and the
# column values of the table, its tiers / zones, surcharges and bus rates.
module FareTables
  module Form
    MONEY = ->(v) { v.presence && v.to_d.round(2) }

    module_function

    # Sectors and areas cleaned in place; a ring under 3 corners or a corner that is not a number → Error.
    def normalize!(f)
      f[:tiers] = Array(f[:tiers]).each_with_index.map { |t, i| clean(t, "#{f[:basis] == 'zone' ? 'Zone' : 'Tier'} #{i + 1}") }
      f[:surcharges] = Array(f[:surcharges]).each_with_index.map { |x, i| clean(x, x[:name].to_s.strip.presence || "Surcharge #{i + 1}") }
      f
    end

    def clean(row, label)
      row.merge(sectors: sectors(row[:sectors]), areas: areas(row[:areas], label))
    end

    def sectors(v) = (v.is_a?(Array) ? v : v.to_s.split(/[\s,;]+/)).map { it.to_s.gsub(/\D/, "")[0, 2] }.select { it.length == 2 }.uniq

    def areas(list, label)
      Array(list).each_with_index.map do |a, i|
        ring = Array(a[:latlngs]).map { |ll| Array(ll).first(2).map { Float(it) } }
        raise ApplicationService::Error, "#{label}: area #{i + 1} needs at least 3 corners" if ring.size < 3 || ring.any? { it.size < 2 }

        { exclude: ActiveModel::Type::Boolean.new.cast(a[:exclude]) || false, latlngs: ring }
      end
    rescue ArgumentError, TypeError
      raise ApplicationService::Error, "#{label}: map corners must be [lat, lng] numbers"
    end

    # A home counts when it is inside an outline that is not a cut-out (HTML areaHas: at least one "add" ring).
    def area?(row) = Array(row[:areas]).any? { !it[:exclude] }

    def table(f)
      small = f[:small] || {}
      express = f[:express] || {}
      cca = f[:cca] || {}
      riders = cca[:riders] || {}
      bill = f[:bill_to] || {}
      {
        payer: f[:payer] || "parents", bill_to_name: bill[:name].presence, bill_to_contact: bill[:contact].presence, bill_to_email: bill[:email].presence,
        basis: f[:basis] || "distance", trip: f[:trip] || "both", cycle: f[:cycle] || "period", months: Array(f[:months]).map(&:to_i).uniq.sort,
        distribution: f[:distribution] || "equal", one_way_type: f.dig(:one_way, :type) || "pct", one_way_value: MONEY.(f.dig(:one_way, :value)),
        by_size: !!f[:by_size], small_on: !!small[:on], small_type: small[:type] || "pct", small_value: MONEY.(small[:value]),
        small_seats: small[:seats].presence || 15, express_on: !!express[:on], express_type: express[:type] || "pct", express_value: MONEY.(express[:value]),
        cca_on: !!cca[:on], cca_per: cca[:per] || "trip", cca_price: cca[:price] || "fixed", cca_fixed: MONEY.(cca[:fixed]),
        cca_split: cca[:split] || "equal", cca_with_services: !!cca[:with_services], bus_count: f[:bus_count] || "plan"
      }.merge(rider_rules(riders))
    end

    # CCA / ASA for riders not on the bus, AM only and PM only: cca_non_on, cca_non_type, cca_non_amount, …
    def rider_rules(riders)
      %i[non am pm].each_with_object({}) do |k, h|
        r = riders[k] || {}
        h[:"cca_#{k}_on"] = !!r[:on]
        h[:"cca_#{k}_type"] = r[:type] || "pct"
        h[:"cca_#{k}_amount"] = MONEY.(r[:amount])
      end
    end

    def size_columns(f) = f[:by_size] ? Array(f[:size_columns]).each.with_index(1).map { |c, i| { position: i, max_seats: c[:max_seats].presence } } : []

    def tier(t)
      { max_km: t[:max_km].presence, name: t[:name].presence, sectors: t[:sectors], **prices(t),
        small_fare: MONEY.(t[:small_fare]), express_fare: MONEY.(t[:express_fare]), cca_fare: MONEY.(t[:cca_fare]) }
    end

    def surcharge(x)
      { name: x[:name].to_s.strip, sectors: x[:sectors], kind: x[:kind] || "flat", amount: MONEY.(x[:amount]),
        one_way_kind: x[:one_way_kind] || "same", one_way_value: MONEY.(x[:one_way_value]) }
    end

    def bus_rates(f) = Array(f[:bus_rates]).select { it[:rate].present? }.map { { bus_type: it[:bus_type], rate: MONEY.(it[:rate]), booked_runs: it[:booked_runs].presence } }

    def area_rows(row) = Array(row[:areas]).each.with_index(1).map { |a, i| { position: i, exclude: a[:exclude], ring: a[:latlngs] } }

    def prices(t)
      { fare: MONEY.(t[:fare]), pm_fare: MONEY.(t[:pm_fare]), one_way_fare: MONEY.(t[:one_way_fare]),
        period_fares: Array(t[:period_fares]).map { MONEY.(it) || 0 }, period_pm_fares: Array(t[:period_pm_fares]).map { MONEY.(it) || 0 } }
    end
  end
end
