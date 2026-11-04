# A replacement bus on a School Bus route for a date range (Scheduler drag with a range, or the route drawer's Replacement
# Buses): replacements overlapping the dates are cut around the new one, then it is added (unless it is the route's own
# regular bus); the runs follow. When we arrange the bus, its cost per day goes with it (taken from the route's operator
# unless told not to). From the drawer the bus can be one "not in our list": by plate, with its company — a Transport
# Operator (the bus is added to its fleet) or a company typed in (added as an External Vehicle).
module SchoolRoutes
  class Replace < ApplicationService
    def initialize(route:, from:, to:, user:, vehicle: nil, plate: nil, operator_id: nil, company: nil, arranged_by: "operator",
                   daily_rate: nil, deduct: true, reason: nil, sync: true)
      @route = route
      @from = from
      @to = to || from
      @user = user
      @vehicle = vehicle
      @plate = plate.to_s.strip.upcase.presence
      @operator_id = operator_id.presence
      @company = company.to_s.strip.presence
      @rep = { arranged_by: arranged_by.presence || "operator", daily_rate: (daily_rate.presence if arranged_by == "us"),
               deduct_from_operator: arranged_by == "us" && ActiveModel::Type::Boolean.new.cast(deduct) != false, reason: reason.to_s.strip.presence }
      @sync = sync
    end

    def call
      raise Error, "Pick the start date" unless @from
      raise Error, "End date is before the start date" if @to < @from
      raise Error, "Enter the replacement bus plate" if @vehicle.nil? && @plate.nil?
      raise Error, "Enter the company that owns the bus" if @vehicle.nil? && @operator_id.nil? && @company.nil?
      raise Error, "Enter the cost per day" if @rep[:arranged_by] == "us" && @rep[:daily_rate].to_d <= 0

      SchoolRoute.transaction do
        vehicle = @vehicle || outside_bus
        cut
        added = @route.replacements.create!(vehicle:, starts_on: @from, ends_on: @to, created_by: @user, **@rep) unless vehicle.id == @route.regular_vehicle_id(@from)
        Occurrences::Sync.call(routes: [ @route ], from: [ @from, Date.current ].max, to: [ @to, @from ].max) if @sync
        added
      end
    end

    # Cut the dates out of overlapping replacements.
    def cut
      @route.replacements.where("starts_on <= ? AND ends_on >= ?", @to, @from).find_each do |r|
        before = r.starts_on < @from ? [ r.starts_on, @from - 1 ] : nil
        after = r.ends_on > @to ? [ @to + 1, r.ends_on ] : nil
        r.destroy!
        [ before, after ].compact.each { |a, z| @route.replacements.create!(r.attributes.except("id", "created_at", "updated_at").merge("starts_on" => a, "ends_on" => z)) }
      end
    end

    private

    # "Bus not in our list": the bus of that plate if the company has it, else added to the operator's fleet or as an
    # External Vehicle of the company typed in.
    def outside_bus
      found = Vehicle.kept.find_by(plate: Vehicle.normalize_value_for(:plate, @plate))
      return found if found

      if @operator_id
        Vehicle.create!(plate: @plate, operator: Operator.kept.find(@operator_id))
      else
        ExternalVehicles::Create.call(params: { plate: @plate, company: { name: @company } }, company: ActsAsTenant.current_tenant, user: @user)
      end
    end
  end
end
