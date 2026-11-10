# Bus Fares › Save & Lock (needs the year's calendar locked): checks the table as the wizard does, saves it whole and
# locks it with each billing period's school days frozen (period_snapshot). Tiers / zones and surcharges are kept by
# `id` (updated in place, new ones added, missing ones removed), so Extra Charges keep their tier targets; a tier an
# Extra Charge targets cannot be removed. Size columns, tier sizes, bus rates and drawn areas are written again.
module FareTables
  class Save < ApplicationService
    def initialize(year, params, user:)
      @year = year
      @f = params
      @user = user
    end

    def call
      school = @year.school
      raise Error, "Save and lock the Terms & Semesters first" unless SchoolSetup.locked?(school:, year: @year, section: :calendar)

      SchoolSetup.ensure_unlocked!(school:, year: @year, section: :fares)
      Form.normalize!(@f)
      periods = FareTables.periods(@year, nil, cycle: @f[:cycle], months: Array(@f[:months]).map(&:to_i))
      problem = Check.problem(@f, periods) and raise Error.new(problem[:message], details: problem.except(:message))

      FareTable.transaction do
        table = @year.fare_table || @year.build_fare_table
        table.update!(Form.table(@f).merge(period_snapshot: periods.map { [ it[:school_days], it[:cca_days] ] }))
        children(table)
        SchoolSetup.lock!(school:, year: @year, section: :fares, user: @user)
        table
      end
    end

    private

    def children(table)
      FareTierSize.where(fare_tier_id: table.tiers.select(:id)).delete_all
      [ table.size_columns, table.bus_rates ].each(&:delete_all)
      cols = Form.size_columns(@f).map { table.size_columns.create!(it) }
      tiers = sync(table.tiers, @f[:tiers]) { Form.tier(it) }
      tiers.zip(@f[:tiers]).each do |tier, t|
        Array(t[:sizes]).each_with_index do |z, k|
          col = cols[k + 1] or next
          tier.sizes.create!(fare_size_column: col, **Form.prices(z))
        end
      end
      sync(table.surcharges, @f[:surcharges]) { Form.surcharge(it) }
      Form.bus_rates(@f).each { table.bus_rates.create!(it) }
    end

    # Rows matched by id (ids of other tables are taken as new rows); the rest of the old rows go. Areas written again.
    def sync(rows, list)
      old = rows.includes(:areas).index_by(&:id)
      kept = list.each.with_index(1).map do |x, i|
        row = old.delete(x[:id].to_i) || rows.build
        row.update!(**yield(x), position: i)
        row.areas.delete_all
        Form.area_rows(x).each { row.areas.create!(it) }
        row
      end
      drop!(old.values)
      kept
    end

    def drop!(gone)
      return if gone.empty?

      used = FareAdjustmentTarget.where(fare_tier_id: gone.grep(FareTier).map(&:id)).includes(:fare_adjustment, :fare_tier).first
      if used
        t = used.fare_tier
        raise Error, "#{t.name.presence || "Tier #{t.position}"} is used by the Extra Charge \"#{used.fare_adjustment.name}\". Keep it, or remove it from that charge first"
      end
      gone.first.class.where(id: gone.map(&:id)).delete_all
    end
  end
end
