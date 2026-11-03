# A saved fare table in the same shape the wizard sends (PUT /academic_years/:id/fares), so the screen can edit and
# send it back; tiers carry their id (Extra Charges pick tiers by id).
module FareTables
  module Present
    module_function

    def call(t)
      cols = t.size_columns.to_a
      {
        payer: t.payer, bill_to: { name: t.bill_to_name, contact: t.bill_to_contact, email: t.bill_to_email }, basis: t.basis, trip: t.trip,
        cycle: t.cycle, months: t.months, distribution: t.distribution, one_way: { type: t.one_way_type, value: t.one_way_value },
        by_size: t.by_size, size_columns: cols.map { { max_seats: it.max_seats } },
        tiers: t.tiers.map do |x|
          prices(x).merge(id: x.id, max_km: x.max_km, name: x.name, sectors: x.sectors, area: x.area, small_fare: x.small_fare,
                          express_fare: x.express_fare, cca_fare: x.cca_fare,
                          sizes: cols.drop(1).map { |c| prices(x.sizes.find { it.fare_size_column_id == c.id }) })
        end,
        surcharges: t.surcharges.map { it.slice(:name, :sectors, :area, :kind, :amount, :one_way_kind, :one_way_value).symbolize_keys },
        small: { on: t.small_on, type: t.small_type, value: t.small_value, seats: t.small_seats },
        express: { on: t.express_on, type: t.express_type, value: t.express_value },
        cca: { on: t.cca_on, per: t.cca_per, price: t.cca_price, fixed: t.cca_fixed, split: t.cca_split, with_services: t.cca_with_services,
               riders: %w[non am pm].to_h { |k| [ k, { on: t[:"cca_#{k}_on"], type: t[:"cca_#{k}_type"], amount: t[:"cca_#{k}_amount"] } ] } },
        bus_count: t.bus_count, bus_rates: t.bus_rates.map { { bus_type: it.bus_type, rate: it.rate, booked_runs: it.booked_runs } }
      }
    end

    def prices(x)
      return { fare: nil, pm_fare: nil, one_way_fare: nil, period_fares: [], period_pm_fares: [] } unless x

      { fare: x.fare, pm_fare: x.pm_fare, one_way_fare: x.one_way_fare, period_fares: x.period_fares, period_pm_fares: x.period_pm_fares }
    end
  end
end
