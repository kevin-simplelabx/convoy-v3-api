# What happened to one run, as a rider sees it (inventory §3). Cancelled and Different bus come from the resolved occurrence:
# the bus on the run is not the regular one (a replacement, or a drag by hand); Relief driver = the regular driver was
# replaced on the same bus; a No Fixed Bus route never has a bus change (the plate of the day is shown instead).
#   Change.of(occ, trip:, regular_vehicle_id:) -> { kind: "cancelled" | "bus" | "driver", ... } or nil
module ConvoyApp
  module Shuttles
    module Change
      # Worst first: what a timing shows when its buses differ.
      ORDER = %w[cancelled bus driver].freeze

      module_function

      def of(occ, trip:, regular_vehicle_id:)
        return { kind: "cancelled", at: occ.cancelled_at, by_client: occ.cancelled_by_client } if occ.cancelled?
        return if occ.vehicle_id.nil? || trip.no_fixed_bus

        if regular_vehicle_id && occ.vehicle_id != regular_vehicle_id
          { kind: "bus", regular_vehicle_id:, set_at: occ.replacement&.updated_at }
        elsif occ.replacement&.kind_drv? || occ.original_driver_id || occ.original_operator_driver_id
          { kind: "driver", set_at: occ.replacement&.updated_at }
        end
      end

      # The strongest change of several buses (nil when none).
      def worst(changes) = ORDER.find { |k| changes.any? { it&.dig(:kind) == k } }
    end
  end
end
