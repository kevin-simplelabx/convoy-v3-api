# Bus Fares › Save & Lock (needs the year's calendar locked): checks the table as the wizard does, saves it whole and
# locks it with each billing period's school days frozen (period_snapshot).
module FareTables
  class Save < ApplicationService
    MONEY = ->(v) { v.presence && v.to_d.round(2) }

    def initialize(year, params, user:)
      @year = year
      @f = params
      @user = user
    end

    def call
      school = @year.school
      raise Error, "Save and lock the Terms & Semesters first" unless SchoolSetup.locked?(school:, year: @year, section: :calendar)

      SchoolSetup.ensure_unlocked!(school:, year: @year, section: :fares)
      @f[:tiers] = Array(@f[:tiers]).map { it.merge(sectors: sectors(it[:sectors])) }
      @f[:surcharges] = Array(@f[:surcharges]).map { it.merge(sectors: sectors(it[:sectors])) }
      periods = FareTables.periods(@year, nil, cycle: @f[:cycle], months: Array(@f[:months]).map(&:to_i))
      problem = Check.call(@f, periods) and raise Error, problem

      FareTable.transaction do
        table = @year.fare_table || @year.build_fare_table
        table.update!(attributes.merge(period_snapshot: periods.map { [ it[:school_days], it[:cca_days] ] }))
        [ table.tiers, table.size_columns, table.surcharges, table.bus_rates ].each(&:delete_all)
        children(table)
        SchoolSetup.lock!(school:, year: @year, section: :fares, user: @user)
        table
      end
    end

    private

    def sectors(v) = (v.is_a?(Array) ? v : v.to_s.split(/[\s,;]+/)).map { it.to_s.gsub(/\D/, "")[0, 2] }.select { it.length == 2 }.uniq

    def attributes
      f = @f
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

    def children(table)
      cols = @f[:by_size] ? Array(@f[:size_columns]).each_with_index.map { |c, i| table.size_columns.create!(position: i + 1, max_seats: c[:max_seats].presence) } : []
      Array(@f[:tiers]).each.with_index(1) do |t, i|
        tier = table.tiers.create!(position: i, max_km: t[:max_km].presence, name: t[:name].presence, sectors: t[:sectors], area: t[:area].presence,
                                   **prices(t), small_fare: MONEY.(t[:small_fare]), express_fare: MONEY.(t[:express_fare]), cca_fare: MONEY.(t[:cca_fare]))
        Array(t[:sizes]).each_with_index do |z, k|
          col = cols[k + 1] or next
          tier.sizes.create!(fare_size_column: col, **prices(z))
        end
      end
      Array(@f[:surcharges]).each.with_index(1) do |x, i|
        table.surcharges.create!(position: i, name: x[:name].strip, sectors: x[:sectors], area: x[:area].presence, kind: x[:kind] || "flat",
                                 amount: MONEY.(x[:amount]), one_way_kind: x[:one_way_kind] || "same", one_way_value: MONEY.(x[:one_way_value]))
      end
      Array(@f[:bus_rates]).select { it[:rate].present? }.each do |r|
        table.bus_rates.create!(bus_type: r[:bus_type], rate: MONEY.(r[:rate]), booked_runs: r[:booked_runs].presence)
      end
    end

    def prices(t)
      { fare: MONEY.(t[:fare]), pm_fare: MONEY.(t[:pm_fare]), one_way_fare: MONEY.(t[:one_way_fare]),
        period_fares: Array(t[:period_fares]).map { MONEY.(it) || 0 }, period_pm_fares: Array(t[:period_pm_fares]).map { MONEY.(it) || 0 } }
    end
  end
end
