# Extra Charge preview (HTML adjForm `prev`): the next 4 bills from its first month for one target — its first tier /
# bus size, or the table's first — with and without it (the school's other charges included), and the example it shows
# ("0 to 3 km, 2-way rider").
module ExtraCharges
  class Preview
    def self.call(year, params, except_id: nil) = new(year, params, except_id).call

    def initialize(year, params, except_id)
      @year = year
      @params = params
      @except = except_id
    end

    # { rows: [{ bill, before, after, change }], example: } (no rows without a locked table).
    def call
      table = @year.fare_table or return { rows: [], example: nil }
      periods = FareTables.periods(@year, table)
      calc = FareTables::Calc.call(table, periods)
      targets = Targets.call(table, @params)
      first = targets.first
      target = first ? (first[:fare_tier_id] || "bus:#{first[:bus_type]}") : nil
      row = calc.find { |r| target.nil? || (r[:tier_id] || "bus:#{r[:bus_type]}") == target } || calc.first or return { rows: [], example: nil }
      target ||= row[:tier_id] || "bus:#{row[:bus_type]}"
      base = row[:std][:two] || row[:std][:one] || row[:std][:am]
      draft = FareAdjustment.new(kind: @params[:kind], value: @params[:value].presence&.to_d, from_month: month(@params[:from_month]),
                                 to_month: @params[:kind] == "once" ? nil : month(@params[:to_month]))
      targets.each { draft.targets.build(it) }
      others = @year.school.fare_adjustments.where.not(id: @except).includes(:targets).to_a
      from = draft.from_month || Date.current.beginning_of_month
      rows = periods.each_with_index.select { |p, _| p[:starts_on] && p[:starts_on].beginning_of_month >= from }.first(4).map do |p, i|
        m = p[:starts_on].beginning_of_month
        b0 = base[:periods][i]
        before = FareTables.adjusted(b0, m, target, others) + FareTables.one_offs(m, target, others)
        after = FareTables.adjusted(b0, m, target, others + [ draft ]) + FareTables.one_offs(m, target, others + [ draft ])
        { bill: p[:label], before:, after:, change: after - before }
      end
      { rows: FareTables.money_tree(rows), example: "#{row[:label]}, #{row[:std][:two] ? '2-way' : '1-way'} rider" }
    end

    private

    def month(v)
      v.present? ? Date.strptime(v.to_s[0, 7], "%Y-%m") : nil
    rescue Date::Error
      raise ApplicationService::Error, "Months must look like 2026-11"
    end
  end
end
