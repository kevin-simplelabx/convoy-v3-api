# Drawer, recurring shuttle runs: on how many of its last 5 dates this run slot was moved to another bus by hand,
# and the bus it went to most. Suggest making that the regular bus (a drop From This Date On) or No Fixed Bus.
module Occurrences
  class BusPattern < ApplicationService
    LOOK_BACK = 5

    def initialize(occ)
      @occ = occ
    end

    def call
      trip = @occ.trip
      return nil unless trip&.corporate_shuttle? && trip.recurring? && @occ.persisted?

      last = TripOccurrence.visible.where(trip_id: trip.id, trip_run_id: @occ.trip_run_id, slot_no: @occ.slot_no, part: 1)
                           .where(date: ..@occ.date).order(date: :desc).limit(LOOK_BACK).to_a
      moved = last.select { |o| o.overridden?(:vehicle_id) && o.vehicle_id }
      top_id, = moved.map(&:vehicle_id).tally.max_by { |_, n| n }
      top = top_id && Vehicle.find_by(id: top_id)
      {
        no_fixed_bus: trip.no_fixed_bus, dates: last.size, moved: moved.size,
        suggest: !trip.no_fixed_bus && last.size >= 3 && moved.size >= 3,
        top_vehicle_id: top&.id, top_plate: top&.plate
      }
    end
  end
end
