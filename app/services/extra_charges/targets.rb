# The targets of an Extra Charge as sent (`tier_ids`, `bus_types`), checked against the year's fare table: tiers / zones
# of that table when riders pay, bus sizes when the school pays per bus (HTML: the form lists fareTiers or busTiers).
# Returns the target rows ({ fare_tier_id: } / { bus_type: }); empty = every rider.
module ExtraCharges
  module Targets
    module_function

    def call(table, params)
      tier_ids = Array(params[:tier_ids]).compact_blank.map(&:to_i).uniq
      bus_types = Array(params[:bus_types]).compact_blank.map(&:to_s).uniq
      if table.per_bus?
        raise ApplicationService::Error, "The school pays per bus. Pick bus sizes, not tiers" if tier_ids.any?
        raise ApplicationService::Error, "Pick bus sizes the fares have a rate for" unless (bus_types - table.bus_rates.map(&:bus_type)).empty?
      else
        raise ApplicationService::Error, "Pick bus sizes only when the school pays per bus" if bus_types.any?
        raise ApplicationService::Error, "Pick #{table.zones? ? 'zones' : 'tiers'} of this year's Bus Fares" unless (tier_ids - table.tiers.map(&:id)).empty?
      end
      tier_ids.map { { fare_tier_id: it } } + bus_types.map { { bus_type: it } }
    end
  end
end
