# Bus Fares wizard preview of a draft table (nothing is saved): the billing periods it gives with their school days
# counted from the calendar now, the fares worked out per tier and bill as GET /fares does, and the first wizard check
# that fails ({ message, step, step_name } or nil) — so each step can show its numbers before Save & Lock.
module FareTables
  class Preview < ApplicationService
    def initialize(year, params)
      @year = year
      @f = params
    end

    def call
      Form.normalize!(@f)
      periods = FareTables.periods(@year, nil, cycle: @f[:cycle], months: Array(@f[:months]).map(&:to_i))
      { periods:, fares: periods.empty? ? [] : Calc.call(draft, periods), problem: Check.problem(@f, periods) }
    end

    private

    # The table in memory: size columns, tiers with their sizes, bus rates (Calc reads only these).
    def draft
      table = FareTable.new(Form.table(@f))
      cols = Form.size_columns(@f).map { table.size_columns.build(it) }
      @f[:tiers].each.with_index(1) do |t, i|
        tier = table.tiers.build(**Form.tier(t), position: i)
        Array(t[:sizes]).each_with_index { |z, k| (col = cols[k + 1]) && tier.sizes.build(fare_size_column: col, **Form.prices(z)) }
      end
      Form.bus_rates(@f).each { table.bus_rates.build(it) }
      table
    end
  end
end
