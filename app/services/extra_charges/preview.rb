# Extra Charge preview: the next 4 bills from its first month for one target (its first, or the first tier / bus size),
# with and without it (other charges included).
module ExtraCharges
  class Preview
    def self.call(year, params, except_id: nil) = new(year, params, except_id).call

    def initialize(year, params, except_id)
      @year = year
      @params = params
      @except = except_id
    end

    def call
      table = @year.fare_table or return []
      periods = FareTables.periods(@year, table)
      calc = FareTables::Calc.call(table, periods)
      target = Array(@params[:targets]).first.presence || (table.per_bus? ? "bus:#{table.bus_rates.first&.bus_type}" : table.tiers.first&.id.to_s)
      row = calc.find { |r| (r[:tier_id] || "bus:#{r[:bus_type]}").to_s == target } || calc.first or return []
      base = row[:std][:two] || row[:std][:one] || row[:std][:am]
      draft = FareAdjustment.new(@params.slice(:name, :kind, :value).merge(from_month: month(@params[:from_month]), to_month: month(@params[:to_month]),
                                                                           targets: Array(@params[:targets]).map(&:to_s)))
      draft.valid?
      others = @year.school.fare_adjustments.where.not(id: @except).to_a
      from = draft.from_month || Date.current.beginning_of_month
      periods.each_with_index.select { |p, _| p[:starts_on] && p[:starts_on].beginning_of_month >= from }.first(4).map do |p, i|
        m = p[:starts_on].beginning_of_month
        b0 = base[:periods][i]
        before = FareTables.adjusted(b0, m, target, others) + FareTables.one_offs(m, target, others)
        after = FareTables.adjusted(b0, m, target, others + [ draft ]) + FareTables.one_offs(m, target, others + [ draft ])
        { bill: p[:label], before:, after:, change: after - before }
      end
    end

    private

    def month(v) = v.present? ? Date.strptime(v.to_s[0, 7], "%Y-%m") : nil
  end
end
