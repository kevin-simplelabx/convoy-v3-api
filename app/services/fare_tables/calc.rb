# The fare table as parents see it (port of fareCalc in logic/fares.js): for every tier or zone (or bus size, when the
# school pays per bus), each fare kind — two (2-way), one (1-way), am, pm — as { annual, periods: [per bill] }, for the
# standard bus, Small Bus, Express and each bus size column. An amount is spread over the bills by weight to the cent,
# the last bill taking the rounding (fdist).
module FareTables
  class Calc
    def self.call(table, periods) = new(table, periods).call

    def initialize(table, periods)
      @t = table
      @p = periods
      total = periods.sum { it[:school_days] }
      @w = @t.distribution == "prorated" && total.positive? ? periods.map { it[:school_days] } : periods.map { 1 }
      @avg = periods.any? ? total.to_d / periods.size : 0
    end

    def call
      return bus_rates if @t.per_bus?

      cols = size_columns
      @t.tiers.each_with_index.map do |tier, i|
        std = fares(tier)
        out = { tier_id: tier.id, position: tier.position, label: tier_label(i), std:, small: service(:small, tier, std), express: service(:express, tier, std) }
        out[:sizes] = cols.drop(1).map do |c|
          # by id once saved; a draft (wizard preview) has no ids yet, so by the column object
          src = tier.sizes.find { c[:id] ? it.fare_size_column_id == c[:id] : it.fare_size_column.equal?(c[:col]) }
          { column: c[:label], fares: fares(src) }
        end
        out
      end
    end

    def size_columns
      return [ { id: nil, label: "Standard" } ] unless @t.by_size

      cols = @t.size_columns.to_a
      cols.each_with_index.map do |c, i|
        { id: c.id, col: c, label: column_label(cols, i) }
      end
    end

    def column_label(cols, i)
      lo = i.zero? ? 0 : cols[i - 1].max_seats.to_i
      return "Up to #{cols[i].max_seats || '?'} Seats" if i.zero?
      return "Above #{lo} Seats" if i == cols.size - 1

      "#{lo + 1} to #{cols[i].max_seats || '?'} Seats"
    end

    def tier_label(i)
      list = @t.tiers
      return (list[i].name.presence || "Zone #{i + 1}") if @t.zones?
      return (i.zero? ? "Any distance" : "Above #{km(list[i - 1].max_km)} km") if i == list.size - 1

      "#{i.zero? ? '0' : km(list[i - 1].max_km)} to #{km(list[i].max_km)} km"
    end

    private

    def km(v) = v.nil? ? "?" : v.to_d.to_s("F").sub(/\.0\z/, "")
    def r2(x) = x.to_d.round(2)
    def num(x) = x.nil? ? 0.to_d : x.to_d
    def mk(amount, w) = { annual: r2(amount), periods: fdist(r2(amount), w) }
    def from_p(list) = { annual: r2(list.sum(0.to_d)), periods: list }

    # Spread an amount over the bills by weight, to the cent; the last bill takes the rounding.
    def fdist(amount, w)
      sw = w.sum
      out = w.map { |x| r2(sw.positive? ? amount * x / sw : amount / [ w.size, 1 ].max) }
      out[-1] = r2(amount - out[0...-1].sum(0.to_d)) if out.any?
      out
    end

    # A fixed amount per bill (per bill), or scaled by the bill's school days against the average (per bill by days).
    def per_bill(amount)
      return @p.map { r2(amount) } unless @t.distribution == "billpro"

      @p.map { |p| r2(amount * (@avg.positive? ? p[:school_days] / @avg : 1)) }
    end

    def entries(src, fare, per)
      case @t.distribution
      when "custom" then @p.each_index.map { |i| r2(num(Array(src&.public_send(per))[i])) }
      when "bill", "billpro" then per_bill(num(src&.public_send(fare)))
      else fdist(r2(num(src&.public_send(fare))), @w)
      end
    end

    def fares(src)
      k = {}
      case @t.trip
      when "ampm"
        am = entries(src, :fare, :period_fares)
        pm = entries(src, :pm_fare, :period_pm_fares)
        k[:two] = from_p(am.zip(pm).map { |a, b| r2(a + b) })
        k[:am] = from_p(am)
        k[:pm] = from_p(pm)
      when "one"
        k[:one] = from_p(entries(src, :fare, :period_fares))
      else
        two = entries(src, :fare, :period_fares)
        k[:two] = from_p(two)
        k[:one] = one_way(src, two, k[:two][:annual])
      end
      k
    end

    def one_way(src, two, annual)
      val = num(@t.one_way_value)
      case @t.one_way_type
      when "custom" then @t.per_bill? ? from_p(per_bill(num(src&.one_way_fare))) : mk(num(src&.one_way_fare), @w)
      when "flat"
        @t.per_bill? ? from_p(two.map { r2([ it - val, 0 ].max) }) : mk([ annual - val, 0 ].max, annual.positive? ? two : @w)
      else from_p(two.map { r2(it * val / 100) })
      end
    end

    # Small Bus / Express: an extra %, an extra amount a year, or the tier's own fare; every fare kind scales the same.
    def service(key, tier, std)
      return nil unless @t.public_send(:"#{key}_on")

      main = @t.trip == "one" ? :one : :two
      base = std[main][:annual]
      val = num(@t.public_send(:"#{key}_value"))
      amount = service_amount(key, tier, base, val)
      q = base.positive? ? amount / base : 0
      out = std.transform_values { |z| mk(z[:annual] * q, z[:annual].positive? ? z[:periods] : @w) }
      out[main] = mk(amount, @w) unless base.positive?
      out
    end

    def service_amount(key, tier, base, val)
      case @t.public_send(:"#{key}_type")
      when "custom" then num(tier.public_send(:"#{key}_fare"))
      when "flat" then base + val
      else base * (1 + (val / 100))
      end
    end

    # School pays per bus: each size's rate on every bill.
    def bus_rates
      @t.bus_rates.map do |r|
        rate = r2(r.rate)
        { bus_type: r.bus_type, label: r.label, booked_runs: r.booked_runs,
          std: { two: { annual: r2(rate * @p.size), periods: @p.map { rate } } }, small: nil, express: nil }
      end
    end
  end
end
