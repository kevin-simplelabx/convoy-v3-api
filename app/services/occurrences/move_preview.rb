# What the drop dialog shows before a run moves to a bus: the choices, the runs moving with it, warnings
# (the bus already has a run then, too few seats, operator hire ending) and the operator cost to prefill.
module Occurrences
  class MovePreview < ApplicationService
    def initialize(occurrence:, vehicle:)
      @occ = occurrence
      @vehicle = vehicle
    end

    def call
      return route_preview if @occ.school_route_id

      trip = @occ.trip
      {
        scopes: trip.recurring? ? %w[one later] : %w[one],
        members: Members.slots(@occ).size,
        warnings: warnings,
        cost: cost_prefill(trip)
      }
    end

    private

    # School route: the three choices, the route's operator and what happens to its pay.
    def route_preview
      route = @occ.school_route
      regular = route.regular_vehicle_id(@occ.date) && Vehicle.find(route.regular_vehicle_id(@occ.date))
      route_op = regular&.operator
      new_op = @vehicle&.operator
      {
        scopes: @vehicle.nil? ? %w[perm] : %w[one range perm], members: 1, warnings:,
        regular: regular&.plate, operator: route_op&.slice(:id, :name),
        same_operator: route_op.present? && route_op.id == new_op&.id,
        ask_who_arranges: route_op.present? && route_op.id != new_op&.id
      }
    end

    def warnings
      return [] if @vehicle.nil?

      c = @occ.company
      list = clashes.map do |o|
        "#{@vehicle.plate} already has #{o.decorate.title} at #{c.format_time(o.start_time)}–#{c.format_time(o.end_time)} on #{c.format_date(o.date)}"
      end
      list << "#{@vehicle.plate} has #{@vehicle.seats} seats. This trip has #{@occ.pax} #{@occ.school_route_id ? 'riders' : 'passengers'}" if @vehicle.seats && @occ.pax > @vehicle.seats
      visits = MaintenanceVisit.on_grid.where(vehicle: @vehicle, date: @occ.date).select { |v| v.starts_at < @occ.ends_at && v.ends_at > @occ.starts_at }
      visits.each { |v| list << "#{@vehicle.plate} is at #{v.workshop&.name || 'the workshop'} #{c.format_time(v.start_time)}–#{c.format_time(v.end_time)}" }
      op = @vehicle.operator
      list << "#{op.name} is set as valid until #{c.format_date(op.valid_until)}" if op && !op.valid_on?(@occ.date)
      list
    end

    def clashes
      members = Members.slots(@occ)
      TripOccurrence.visible.where(vehicle: @vehicle, date: @occ.date).where.not(status: "cancelled")
                    .where("starts_at < ? AND ends_at > ?", @occ.ends_at, @occ.starts_at).includes(:trip)
                    .reject { |o| o.id == @occ.id || (o.trip_id && o.trip_id == @occ.trip_id && members.include?([ o.trip_run_id, o.slot_no ])) }
    end

    # The pay agreed with the bus's operator on this trip, else the trip's operator cost.
    def cost_prefill(trip)
      return nil if @vehicle.nil? || @vehicle.own?

      amount, basis = Assignments.agreed_pay(trip, @vehicle.operator_id)
      if amount then { amount:, basis:, source: "agreed" }
      elsif trip.operator_cost then { amount: trip.operator_cost, basis: trip.disposal? ? "hour" : "run", source: "trip" }
      end
    end
  end
end
