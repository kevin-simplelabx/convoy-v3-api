# The stored runs between two dates. Runs exist up to the horizon (today + Occurrences::Sync::HORIZON_DAYS);
# later dates have none yet: the daily job adds one date each night, from the trips and their rules.
class OccurrenceWindow
  INCLUDES = [ :vehicle, :original_vehicle, :driver, :operator_driver, :client,
               { trip_run: %i[slots times], trip: %i[stops client], school_route: [ :stops, { plan: :school } ] } ].freeze

  def initialize(from:, to:, scope: TripOccurrence.all)
    @from = from
    @to = to
    @scope = scope
  end

  def all = @scope.visible.between(@from, @to).includes(*INCLUDES).chronological.to_a
end
