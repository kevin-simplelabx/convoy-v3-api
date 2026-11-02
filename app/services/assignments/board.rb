# The Assign page for a trip as of a date: every run x vehicle slot with who runs it then (assignment, else the
# trip's own plan), and the assignment history.
module Assignments
  class Board < ApplicationService
    Slot = Data.define(:key, :trip_run_id, :run_key, :run_label, :slot_no, :assignee, :vehicle_id, :plate, :operator_id,
                       :operator_name, :pay_amount, :pay_basis, :assignment_id, :from)

    def initialize(trip, as_of)
      @trip = trip
      @date = [ as_of, trip.starts_on ].max
    end

    def call
      runs = @trip.corporate_shuttle? ? @trip.runs.to_a : [ nil ]
      runs.flat_map { |run| (1..@trip.vehicles_count).map { |n| slot(run, n) } }
    end

    private

    def slot(run, n)
      a = @trip.assignments.select { |x| x.effective_from <= @date && x.covers?(run&.id, n) }.max_by { |x| [ x.effective_from, x.id ] }
      vehicle = a ? a.vehicle : planned(run, n)
      assignee = a ? a.assignee : (vehicle.nil? ? "none" : (vehicle.own? ? "own" : "operator"))
      operator = a&.operator || vehicle&.operator
      Slot.new(key: "#{run&.key || 'trip'}|#{n}", trip_run_id: run&.id, run_key: run&.key, run_label: run && label(run),
               slot_no: n, assignee:, vehicle_id: vehicle&.id, plate: vehicle&.plate, operator_id: operator&.id,
               operator_name: operator&.name, pay_amount: a&.pay_amount, pay_basis: a&.pay_basis, assignment_id: a&.id,
               from: a&.effective_from)
    end

    def planned(run, n)
      rs = run&.slots&.find { |s| s.slot_no == n }
      return nil if rs&.unassigned?

      rs&.vehicle || @trip.vehicle_slots.find { |s| s.slot_no == n }&.vehicle
    end

    def label(run) = "#{run.direction == 2 ? 'Return ' : ''}#{run.start_time_hm}"
  end
end
