# HR > Rate Plans > Coverage: the period that pays each half hour (at its middle) of Mon..Sun and PH, the gaps where no
# period pays (jobs there are paid S$0) and the periods whose rates are still empty.
module Pay
  class Coverage < ApplicationService
    LABELS = %w[mon tue wed thu fri sat sun ph].freeze
    PREV = { "mon" => "sun", "tue" => "mon", "wed" => "tue", "thu" => "wed", "fri" => "thu", "sat" => "fri", "sun" => "sat", "ph" => "ph" }.freeze

    def initialize(plan:)
      @plan = plan
      @lookup = RateLookup.new(plan)
    end

    def call
      rows = LABELS.map { |day| { day:, cells: Array.new(48) { |c| @lookup.cover(day, PREV[day], (c * 30) + 15)&.id } } }
      { rows:, periods: @plan.periods.map { |p| { id: p.id, name: p.name } }, gaps: gaps(rows), empty_rates: empty_rates }
    end

    private

    # [{ day, from, to }] runs of half hours with no period.
    def gaps(rows)
      rows.flat_map do |row|
        row[:cells].each_with_index.chunk_while { |(a, i), (b, j)| a.nil? && b.nil? && j == i + 1 }
                   .select { |run| run.first.first.nil? }
                   .map { |run| { day: row[:day], from: Clock.hm(run.first.last * 30), to: run.last.last == 47 ? "24:00" : Clock.hm((run.last.last + 1) * 30) } }
      end
    end

    # [{ period, vehicle_type }] where a picked type has no per-trip rate.
    def empty_rates
      types = @plan.vehicle_types.to_a
      @plan.periods.flat_map do |p|
        types.filter_map { |t| { period: p.name, vehicle_type: t.name } if p.rates.find { |r| r.vehicle_type_id == t.id }&.per_trip.nil? }
      end
    end
  end
end
