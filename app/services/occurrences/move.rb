# A run dropped on another bus (or on Unassigned) in the Scheduler. Its Runs That Move Together go with it.
# - scope "one": this date only (the run's vehicle is overridden; Sync keeps it).
# - scope "later": From This Date On, written as an assignment (shown on the Assign page).
# - a trip that does not repeat, or a drop on the first date of a series, changes the trip's own vehicle.
# A non-own bus may carry the cost agreed with its operator: per run, day, month, or per hour (Disposal).
module Occurrences
  class Move < ApplicationService
    SCOPES = %w[one later].freeze

    def initialize(occurrence:, vehicle:, scope:, user:, cost: nil, cost_basis: nil, lock_version: nil)
      @occ = occurrence
      @vehicle = vehicle
      @scope = scope.to_s
      @user = user
      @cost = cost.presence&.to_d
      @basis = cost_basis.presence || "run"
      @occ.lock_version = lock_version.to_i if lock_version.present?
    end

    def call
      raise Error, "Pick Just This Date or From This Date On" unless SCOPES.include?(@scope)
      raise Error, "That bus is no longer in use" if @vehicle&.discarded?
      raise Error, "This run does not run that day (#{@occ.skip_reason})" if @occ.skipped?

      trip = @occ.trip
      TripOccurrence.transaction do
        @occ.touch # checks lock_version
        members = Members.on_date(@occ)
        if !trip.recurring? || (@scope == "later" && @occ.date <= trip.starts_on) then change_trip(trip, members)
        elsif @scope == "one" then members.each { |m| override(m, members.size) }.then { resync(trip) }
        else assign_from_here(trip, members)
        end
        members.map(&:reload)
      end
    end

    private

    def fleet = @fleet ||= Fleet.new

    # This date only: the bus, its driver and operator; the cost when one was given.
    def override(occ, member_count)
      attrs = Occurrences.vehicle_attrs(fleet, occ.trip, @vehicle&.id, occ.date)
      fields = occ.overridden_fields | [ "vehicle_id" ]
      if @cost && @vehicle && !@vehicle.own?
        attrs[:operator_cost] = cost_per_run(occ, member_count)
        fields |= [ "operator_cost" ]
      end
      occ.update!(attrs.merge(overridden_fields: fields))
    end

    # Replacements on the new bus (Driver Away, Vehicle Down) apply to the moved runs too.
    def resync(trip)
      Sync.call(trips: [ trip ], from: @occ.date, to: @occ.date)
    end

    def cost_per_run(occ, member_count)
      amount = case @basis
      when "hour" then @cost * ((occ.end_time - occ.start_time) / 60.0)
      when "day" then @cost / member_count
      when "month"
                 days = Calendars::Context.for(occ.company, from: occ.date, to: occ.date).trip_dates(occ.trip, occ.date.beginning_of_month, occ.date.end_of_month).size
                 @cost / member_count / [ days, 1 ].max
      else @cost
      end
      amount.round(2)
    end

    # From This Date On: an assignment for the member slots; their bus changes made by hand from this date are dropped.
    def assign_from_here(trip, members)
      keys = members.map { |m| [ m.trip_run_id, m.slot_no ] }
      Assignments::Create.call(
        trip:, effective_from: @occ.date, slots: keys, user: @user,
        assignee: @vehicle.nil? ? "none" : (@vehicle.own? ? "own" : "operator"),
        operator: @vehicle&.operator, vehicle: @vehicle,
        pay_amount: @vehicle && !@vehicle.own? ? (@cost || Assignments.agreed_pay(trip, @vehicle.operator_id)&.first) : nil,
        pay_basis: %w[run day month].include?(@basis) ? @basis : "run"
      )
    end

    # One-off trips (or the first date): the trip's own vehicle slot, or the shuttle run's vehicle.
    def change_trip(trip, members)
      members.each do |m|
        if m.trip_run
          slot = m.trip_run.slots.find_or_initialize_by(slot_no: m.slot_no)
          slot.update!(vehicle: @vehicle, unassigned: @vehicle.nil?)
        else
          trip.vehicle_slots.find_or_initialize_by(slot_no: m.slot_no).update!(vehicle: @vehicle)
        end
        m.update!(overridden_fields: m.overridden_fields - [ "vehicle_id" ])
      end
      Sync.call(trips: [ trip ], from: @occ.date)
      return unless @cost && @vehicle && !@vehicle.own?

      members.each do |m|
        m.reload.update!(operator_cost: cost_per_run(m, members.size), overridden_fields: m.overridden_fields | [ "operator_cost" ])
      end
    end
  end
end
