# The bus a run has before anything is done to it by hand or by a replacement: the latest assignment (layer 2, From This Date
# On) covering the run and slot, else the bus planned on the trip (layer 1: Vehicle for Each Run, else the vehicle slot).
# One place for the Generator and for readers that need "the usual bus" (the Convoy App's shuttle changes).
module Occurrences
  module Regular
    module_function

    # The assignment in force for the slot on the date: the latest effective_from <= date covering it.
    def assignment_on(trip, run, slot, date)
      trip.assignments.select { |a| a.effective_from <= date && a.covers?(run&.id, slot) }.max_by { |a| [ a.effective_from, a.id ] }
    end

    # Vehicle for Each Run, else the trip's vehicle slot (used when no assignment covers the slot).
    def planned_vehicle(trip, run, slot)
      run_slot = run&.slots&.find { |s| s.slot_no == slot }
      return nil if run_slot&.unassigned?

      run_slot&.vehicle_id || trip.vehicle_slots.find { |s| s.slot_no == slot }&.vehicle_id
    end

    def vehicle_id(trip, run, slot, date) = assignment_on(trip, run, slot, date)&.vehicle_id || planned_vehicle(trip, run, slot)
  end
end
