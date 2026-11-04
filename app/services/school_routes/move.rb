# A School Bus route run dropped on another bus (or off its bus) in the Scheduler:
# - one: Just This Trip — a replacement for that school day;
# - range: Replacement for a Date Range (while a bus is in the workshop);
# - perm: Permanent change from this date — the regular bus from the date (no bus = Remove the bus from this date).
# A replacement overlapping the dates is cut around the new one. When we arrange a bus for the route's operator,
# the cost per day goes with it (and is taken from the operator's pay unless told not to).
module SchoolRoutes
  class Move < ApplicationService
    SCOPES = %w[one range perm].freeze

    def initialize(occurrence:, vehicle:, scope:, user:, starts_on: nil, ends_on: nil, arranged_by: "operator", daily_rate: nil, deduct: true, reason: nil)
      @occ = occurrence
      @route = occurrence.school_route
      @vehicle = vehicle
      @scope = scope.to_s
      @user = user
      @from = starts_on.presence ? Date.parse(starts_on.to_s) : occurrence.date
      @to = ends_on.presence ? Date.parse(ends_on.to_s) : @from
      @rep = { arranged_by:, daily_rate: daily_rate.presence, deduct_from_operator: ActiveModel::Type::Boolean.new.cast(deduct) != false, reason: }
    end

    def call
      raise Error, "Pick Just This Trip, a Date Range or a Permanent change" unless SCOPES.include?(@scope)
      raise Error, "Check the dates. The end date is before the start date" if @to < @from
      raise Error, "Pick the bus" if @vehicle.nil? && @scope != "perm"

      SchoolRoute.transaction do
        @scope == "perm" ? change_regular : replace
        @occ.update_columns(overridden_fields: @occ.overridden_fields - %w[vehicle_id]) if @occ.overridden?(:vehicle_id)
        Occurrences::Sync.call(routes: [ @route ], from: [ @from, Date.current ].max, to: [ @to, @from ].max + (@scope == "perm" ? 400 : 0))
      end
      @occ.reload
    end

    private

    def change_regular
      change = @route.vehicle_changes.find_or_initialize_by(effective_from: @from)
      change.update!(vehicle: @vehicle, created_by: @user)
    end

    # Cut the dates out of overlapping replacements, then add this one (unless it puts the regular bus back).
    def replace
      Replace.call(route: @route, vehicle: @vehicle, from: @from, to: @to, user: @user, sync: false, arranged_by: @rep[:arranged_by],
                   daily_rate: @rep[:daily_rate], deduct: @rep[:deduct_from_operator], reason: @rep[:reason])
    end
  end
end
