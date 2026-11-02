# Gives some vehicle slots of a trip to an own bus, an operator (bus named or later) or nobody, from a date on.
# Slots given again on the same date leave the earlier entry of that date. Runs from that date are re-synced and
# their bus changes made by hand are dropped, so the assignment shows.
module Assignments
  class Create < ApplicationService
    # slots: [[trip_run_id or nil, slot_no], ...]
    def initialize(trip:, effective_from:, slots:, assignee:, user:, operator: nil, vehicle: nil, pay_amount: nil, pay_basis: "run")
      @trip = trip
      @from = effective_from
      @slots = slots.uniq
      @attrs = { assignee:, operator: assignee.to_s == "operator" ? (operator || vehicle&.operator) : nil, vehicle:,
                 pay_amount: assignee.to_s == "operator" ? pay_amount : nil, pay_basis:, created_by: user }
    end

    def call
      raise Error, "Tick at least one run" if @slots.empty?
      raise Error, "The first date is before the trip starts" if @from < @trip.starts_on

      TripAssignment.transaction do
        release_same_day
        assignment = @trip.assignments.create!(effective_from: @from, **@attrs)
        @slots.each { |run_id, slot_no| assignment.slots.create!(trip_run_id: run_id, slot_no:) }
        clear_hand_moves
        Occurrences::Sync.call(trips: [ @trip ], from: @from)
        assignment
      end
    end

    private

    def release_same_day
      @trip.assignments.where(effective_from: @from).find_each do |a|
        a.slots.select { |s| @slots.include?([ s.trip_run_id, s.slot_no ]) }.each(&:destroy!)
        a.destroy! if a.slots.reload.empty?
      end
    end

    def clear_hand_moves
      @slots.each do |run_id, slot_no|
        TripOccurrence.where(trip: @trip, trip_run_id: run_id, slot_no:, date: @from..)
                      .where("'vehicle_id' = ANY(overridden_fields)").where("starts_at > ?", Time.current)
                      .update_all("overridden_fields = array_remove(array_remove(overridden_fields, 'vehicle_id'), 'operator_cost')")
      end
    end
  end
end
