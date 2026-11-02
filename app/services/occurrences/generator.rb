# What a trip's occurrences should be between two dates (pure: no writes). One row per date the trip runs
# x shuttle run x vehicle slot (and a second part for a handover), with the layers of .notes/domains/occurrences.md (Layer model) applied in order:
#   1 the trip (times, vehicle slot, Vehicle for Each Run), 2 assignment, 3 hand changes kept on the stored row
#   (bus, operator cost, Today Only shift), 4 replacement. Status (5) is Sync's.
# Sync writes these rows (up to the horizon).
module Occurrences
  class Generator
    Row = Struct.new(:trip_id, :school_route_id, :date, :trip_run_id, :run_key, :slot_no, :part, :client_id, :kind, :trip_label,
                     :start_time, :end_time, :starts_at, :ends_at, :shift_minutes, :pax, :vehicle_id, :driver_id,
                     :operator_driver_id, :driver_name, :driver_phone, :operator_id, :original_vehicle_id, :price,
                     :trip_value, :operator_cost, :trip_assignment_id, :replacement_id, :skip_reason, keyword_init: true) do
      def identity = [ trip_id, school_route_id, date, trip_run_id, slot_no, part ]

      # Changes when anything Sync writes changes, so unchanged rows are skipped.
      def digest = Digest::MD5.hexdigest(to_h.except(:trip_id, :school_route_id, :date, :trip_run_id, :slot_no, :part).to_json)
    end

    def initialize(context:, fleet:, replacements: nil, zone: Time.zone)
      @ctx = context
      @fleet = fleet
      @replacements = replacements
      @zone = zone
    end

    # existing: {identity => TripOccurrence}, the stored rows (their hand changes are layer 3).
    # Dates the calendar skips give rows too (skip_reason set, no price or pay) so Trip History can show them.
    def rows(trip, from, to, existing: {})
      skips = @ctx.trip_skips(trip, from, to)
      dates = (@ctx.trip_dates(trip, from, to) + skips.keys).sort
      return [] if dates.empty?

      replacement_index(from, to)
      pricer = Pricing::TripPrice.new(trip, @ctx)
      slots = (1..trip.vehicles_count).to_a
      runs = trip.corporate_shuttle? ? trip.runs.to_a : [ nil ]
      dates.flat_map do |date|
        runs.each_with_index.flat_map do |run, k|
          slots.flat_map do |slot|
            row = base_row(trip, date, run, k, slot, pricer, runs.size, existing[[ trip.id, nil, date, run&.id, slot, 1 ]])
            next [ skipped(row, skips[date]) ] if skips.key?(date)

            replace(row, trip)
          end
        end
      end
    end

    private

    # A run the calendar skips: kept for history with why, without price, pay or cost.
    def skipped(row, reason)
      row.skip_reason = reason
      row.price = 0
      row.trip_value = 0
      row.operator_cost = nil
      row
    end

    def replacement_index(from, to) = @replacements ||= ReplacementIndex.new(from, to)

    def base_row(trip, date, run, run_index, slot, pricer, run_count, occ)
      base_start = run ? run.start_time : trip.start_time
      base_end = run ? run.end_time : trip.end_time
      shift = @ctx.time_shift(trip.calendar_id, date, base_start, trip.session) + time_change(trip, run, date) + occ&.shift_minutes.to_i
      start_time = base_start + shift
      end_time = base_end + shift

      assignment = assignment_on(trip, run, slot, date)
      vehicle_id = if occ&.overridden?(:vehicle_id) then occ.vehicle_id
      elsif assignment then assignment.vehicle_id
      else planned_vehicle(trip, run, slot)
      end
      bus = Occurrences.vehicle_attrs(@fleet, trip, vehicle_id, date)
      if assignment && !occ&.overridden?(:vehicle_id)
        bus[:operator_id] = assignment.operator_id if assignment.to_operator?
        bus[:operator_cost] = assignment_pay(trip, assignment, date) || bus[:operator_cost] unless assignment.to_own?
      end
      bus[:operator_cost] = occ.operator_cost if occ&.overridden?(:operator_cost)

      Row.new(
        trip_id: trip.id, date:, trip_run_id: run&.id, run_key: run&.key, slot_no: slot, part: 1, client_id: trip.client_id,
        kind: trip.kind, trip_label: label(trip, date, run_index, slot, run),
        start_time:, end_time:, starts_at: at(date, start_time), ends_at: at(date, end_time), shift_minutes: occ&.shift_minutes.to_i,
        pax: share(trip.pax, trip.vehicles_count, slot), price: pricer.run_price(slot:, date:, run:),
        trip_value: trip_value(trip, run, run_count), trip_assignment_id: assignment&.id, original_vehicle_id: nil,
        replacement_id: nil, driver_name: nil, driver_phone: nil, **bus
      )
    end

    # Layer 4: the replacement for the run, if any. A handover gives a second part on the new bus.
    def replace(row, trip)
      rep = @replacements.for(row.trip_id, row.date, row.trip_run_id, row.slot_no, row.vehicle_id, school_route_id: row.school_route_id)
      return [ row ] if rep.nil?

      row.replacement_id = rep.id
      case rep.kind
      when "drv" then new_driver(row, rep, row.vehicle_id)
      when "veh" then new_bus(row, rep, trip, keep_driver: true)
      when "crew" then new_bus(row, rep, trip, keep_driver: false)
      when "hand" then return handover(row, rep, trip)
      end
      [ row ]
    end

    def new_driver(row, rep, vehicle_id)
      if rep.driver_id || rep.operator_driver_id || rep.driver_name
        row.driver_id = rep.driver_id
        row.operator_driver_id = rep.operator_driver_id
        row.driver_name = rep.driver_id || rep.operator_driver_id ? nil : rep.driver_name
        row.driver_phone = rep.driver_id || rep.operator_driver_id ? nil : rep.driver_phone
      else
        d = @fleet.driver_on(vehicle_id, row.date)
        row.driver_id = d.is_a?(Driver) ? d.id : nil
        row.operator_driver_id = d.is_a?(OperatorDriver) ? d.id : nil
      end
    end

    # Vehicle Down keeps the original driver on the new bus; Crew Swap takes the new bus's driver (or the one picked).
    # Arranged by the operator: they pay, the run stays theirs. Arranged by us: the new bus's operator runs it.
    def new_bus(row, rep, trip, keep_driver:)
      row.original_vehicle_id = row.vehicle_id
      row.vehicle_id = rep.vehicle_id
      new_driver(row, rep, rep.vehicle_id) unless keep_driver
      return unless rep.arranged_by_us?

      row.operator_id = @fleet.operator_of(rep.vehicle_id)
      row.operator_cost = @fleet.own?(rep.vehicle_id) || trip.nil? ? nil : trip.operator_cost
    end

    # Handover: part 1 on the original bus until the handover time, part 2 on the new bus from it; trip value shared.
    def handover(row, rep, trip)
      at_min = rep.handover_time
      at_min += 1440 if at_min < row.start_time - 60
      at_min = at_min.clamp(row.start_time + 1, row.end_time - 1)
      first_share, second_share = rep.shares
      second = row.dup
      row.end_time = at_min
      row.ends_at = at(row.date, at_min)
      row.trip_value = (row.trip_value.to_d * first_share).round(2)

      second.part = 2
      second.start_time = at_min
      second.starts_at = at(second.date, at_min)
      second.price = 0
      second.trip_value = (second.trip_value.to_d * second_share).round(2)
      new_bus(second, rep, trip, keep_driver: false)
      [ row, second ]
    end

    # The assignment in force for the slot on the date: the latest effective_from <= date covering it.
    def assignment_on(trip, run, slot, date)
      trip.assignments.select { |a| a.effective_from <= date && a.covers?(run&.id, slot) }.max_by { |a| [ a.effective_from, a.id ] }
    end

    # Agreed pay per run: per run as is; per day shared over the slots it covers; per month also over the month's run days.
    def assignment_pay(trip, assignment, date)
      return nil if assignment.pay_amount.nil?

      n = [ assignment.slots.size, 1 ].max
      amount = assignment.pay_amount.to_d
      amount = case assignment.pay_basis
      when "day" then amount / n
      when "month" then amount / n / [ @ctx.trip_dates(trip, date.beginning_of_month, date.end_of_month).size, 1 ].max
      else amount
      end
      amount.round(2)
    end

    # Vehicle for Each Run, else the trip's vehicle slot (used when no assignment covers the slot).
    def planned_vehicle(trip, run, slot)
      run_slot = run&.slots&.find { |s| s.slot_no == slot }
      return nil if run_slot&.unassigned?

      run_slot&.vehicle_id || trip.vehicle_slots.find { |s| s.slot_no == slot }&.vehicle_id
    end

    # The latest Every Run From This Date change on or before the date (for this run, or for every run).
    def time_change(trip, run, date)
      trip.time_changes.select { |c| c.effective_from <= date && (c.trip_run_id.nil? || c.trip_run_id == run&.id) }
          .max_by { |c| [ c.effective_from, c.trip_run_id ? 1 : 0, c.id.to_i ] }&.minutes.to_i
    end

    # Trip ID: TID + number for the day; vehicles get -n; a shuttle run gets -k counting runs x vehicles.
    def label(trip, date, run_index, slot, run)
      return trip.trip_id_on(date, slot) unless run

      base = trip.trip_id_on(date).sub(/-\d+\z/, "")
      "#{base}-#{(run_index * trip.vehicles_count) + slot}"
    end

    def trip_value(trip, run, run_count)
      value = run&.trip_value || (run&.direction == 2 && trip.trip_value_return) || trip.trip_value
      trip.corporate_shuttle? && trip.trip_value_per_day? ? (value.to_d / [ run_count, 1 ].max).round(2) : value
    end

    # Passengers shared over the vehicles: the first ones take the remainder.
    def share(total, count, slot)
      return total if count <= 1

      (total / count) + (slot <= total % count ? 1 : 0)
    end

    def at(date, minutes) = @zone.local(date.year, date.month, date.day) + minutes.minutes
  end
end
