# The starting card of the Rate Cards page (New Rate Card, and the seed): Off Peak, Peak, Night (Mon to Fri) and
# Weekend and PH (override) for the company's vehicle types. Rates grow with the bus: +S$25 a trip and +S$15 an hour
# for every 10 seats above 13. Distance bands, stop fees and disposal per km are filled in but switched off.
module RateCards
  class Standard
    WEEKDAYS = %w[mon tue wed thu fri].freeze

    # Params for RateCards::Form / Save (the same shape the page sends). base = Off Peak trip rate.
    def self.params(name: "New Rate Card", description: "", base: 55, types: VehicleType.enabled_for(ActsAsTenant.current_tenant).order(:seats))
      new(types, base).params(name, description)
    end

    def initialize(types, base)
      @types = types.to_a
      @base = base
    end

    def params(name, description)
      {
        name:, description:, vehicle_type_ids: @types.map(&:id),
        wait_free_minutes: 10, wait_fee: 15, wait_block_minutes: 15, meet_and_greet: false, meet_and_greet_fee: 0,
        distance_pricing: false, stop_fees: false, disposal_mode: "hourly", disposal_free_km: 0,
        periods: [
          period("Off Peak", WEEKDAYS, [ %w[07:00 19:00] ], false, 0),
          period("Peak", WEEKDAYS, [ %w[05:00 07:00], %w[19:00 21:00] ], false, 10),
          period("Night", WEEKDAYS + [ "sun" ], [ %w[21:00 05:00] ], false, 20),
          period("Weekend and PH", %w[sat sun ph], [ %w[00:00 23:59] ], true, 15)
        ],
        distance_bands: [
          { up_to_km: 20, per_km: false, amounts: by_type { 0 } },
          { up_to_km: 40, per_km: false, amounts: by_type { |k| (25 + (k * 10)).round } },
          { up_to_km: nil, per_km: false, amounts: by_type { |k| (50 + (k * 15)).round } }
        ],
        stop_fee_amounts: by_type { |k| (10 + (k * 4)).round },
        disposal_km_amounts: by_type { |k| (1 + (k * 0.4)).round(2) }
      }
    end

    private

    def period(name, days, ranges, override, add)
      trip = @base + add
      { name:, days:, override:, ranges: ranges.map { |a, b| { starts_at: a, ends_at: b } },
        rates: @types.map { |t| { vehicle_type_id: t.id, trip_rate: (trip + (step(t) * 25)).round, hourly_rate: (trip - 10 + (step(t) * 15)).round } } }
    end

    def by_type = @types.map { |t| { vehicle_type_id: t.id, amount: yield(step(t)) } }
    def step(type) = [ (type.seats - 13) / 10.0, 0 ].max
  end
end
