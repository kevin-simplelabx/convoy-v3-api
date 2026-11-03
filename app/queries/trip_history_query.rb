# Trip History: every run that has run, was cancelled or was skipped by the calendar, up to today, between two dates
# (at most MAX_DAYS). Filters are lists (any value matches): client_id[], vehicle_id[], driver[] (names), operator[]
# (own | none | operator id), kind[], outcome[], on_time[]; needs_look; q; sort (new | old | id | client).
# #facets gives each filter's values with counts (every other filter applied), as the filter chips show them.
# Outcome, vehicle and driver are the corrected ones when Correct Record changed them (vehicle: id, or the plate
# when the plate is not in the fleet).
class TripHistoryQuery
  MAX_DAYS = 366
  DEFAULT_DAYS = 30
  SORTS = {
    "new" => "trip_occurrences.date DESC, trip_occurrences.start_time DESC, trip_occurrences.id DESC",
    "old" => "trip_occurrences.date ASC, trip_occurrences.start_time ASC, trip_occurrences.id ASC",
    "id" => "trip_occurrences.trip_label ASC, trip_occurrences.date DESC",
    "client" => "clients.name ASC NULLS LAST, trip_occurrences.date DESC, trip_occurrences.start_time DESC"
  }.freeze
  INCLUDES = [ :vehicle, :original_vehicle, :driver, :operator_driver, :operator, :client, :history_notes,
               :stop_events, :trip_summary, { correction: %i[vehicle stops] },
               { trip: [], school_route: { plan: :school } } ].freeze

  OUTCOME_SQL = <<~SQL.squish.freeze
    CASE trip_occurrences.status WHEN 'skipped' THEN 'skipped'
      WHEN 'cancelled' THEN CASE WHEN trip_occurrences.driver_end = 'skipped' THEN 'skipped_by_driver'
        WHEN trip_occurrences.cancelled_by_client THEN 'cancelled_by_client' ELSE 'cancelled_by_us' END
      ELSE COALESCE(occurrence_corrections.outcome, 'completed') END
  SQL
  DRIVER_SQL = <<~SQL.squish.freeze
    COALESCE(occurrence_corrections.driver_name, drivers.name, operator_drivers.name, trip_occurrences.driver_name, vehicles.driver_name)
  SQL
  VEHICLE_SQL = <<~SQL.squish.freeze
    CASE WHEN occurrence_corrections.vehicle_plate IS NULL THEN trip_occurrences.vehicle_id::text
         ELSE COALESCE(occurrence_corrections.vehicle_id::text, occurrence_corrections.vehicle_plate) END
  SQL
  OPERATOR_SQL = <<~SQL.squish.freeze
    CASE WHEN trip_occurrences.vehicle_id IS NULL THEN 'none' WHEN trip_occurrences.operator_id IS NULL THEN 'own'
         ELSE trip_occurrences.operator_id::text END
  SQL
  NEEDS_LOOK_SQL = <<~SQL.squish.freeze
    (trip_occurrences.replacement_id IS NOT NULL OR trip_occurrences.issue_reason IS NOT NULL OR occurrence_corrections.id IS NOT NULL
     OR occurrence_trip_summaries.overspeed_seconds > 0
     OR (trip_occurrences.status = 'completed' AND occurrence_corrections.outcome = 'incomplete')
     OR EXISTS (SELECT 1 FROM occurrence_notes n WHERE n.occurrence_id = trip_occurrences.id AND n.occurrence_date = trip_occurrences.date))
  SQL
  DIMENSIONS = {
    client_id: "trip_occurrences.client_id", vehicle_id: VEHICLE_SQL, driver: DRIVER_SQL, operator: OPERATOR_SQL,
    kind: "trip_occurrences.kind", outcome: OUTCOME_SQL
  }.freeze

  attr_reader :from, :to

  def initialize(scope, params, on_time_minutes: 5, today: Date.current)
    @scope = scope
    @params = params
    @today = today
    @dimensions = DIMENSIONS.merge(on_time: on_time_sql(on_time_minutes.to_i))
    @to = [ date(:to) || today, today ].min
    @from = date(:from) || (@to - DEFAULT_DAYS)
    raise ApplicationService::Error, "Pick a From date on or before the To date" if @from > @to
    raise ApplicationService::Error, "Trip History shows up to a year at a time" if (@to - @from).to_i >= MAX_DAYS
  end

  def call
    filtered.includes(*INCLUDES).order(Arel.sql(SORTS.fetch(@params[:sort].to_s, SORTS["new"])))
  end

  # { client_id: [{ value, label, count }], ... } — counts with every other filter applied.
  def facets
    @dimensions.to_h do |key, sql|
      counts = filtered(skip: key).group(Arel.sql(sql)).count
      [ key, counts.map { |value, count| { value: value.to_s, label: label(key, value), count: } }.sort_by { |f| f[:label].to_s.downcase } ]
    end
  end

  private

  # Same rules as TripHistory.on_time: N/A unless it ran to the end and an arrival time is known.
  def on_time_sql(minutes)
    <<~SQL.squish
      CASE WHEN (#{OUTCOME_SQL}) <> 'completed' OR trip_occurrences.max_delay_minutes IS NULL THEN 'na'
           WHEN trip_occurrences.max_delay_minutes > #{minutes} THEN 'late' ELSE 'on_time' END
    SQL
  end

  def base
    @scope.left_joins(:client, :vehicle, :driver, :operator_driver, :operator, :trip, :correction, :trip_summary, school_route: { plan: :school })
          .where(date: @from..@to, status: %w[completed cancelled skipped])
  end

  def filtered(skip: nil)
    s = base
    @dimensions.each do |key, sql|
      values = Array(@params[key]).compact_blank.map(&:to_s)
      s = s.where("(#{sql})::text IN (?)", values) if key != skip && values.any?
    end
    s = s.where(NEEDS_LOOK_SQL) if ActiveModel::Type::Boolean.new.cast(@params[:needs_look])
    search(s, @params[:q])
  end

  # Trip ID, trip, client, plate, driver, operator, school or route.
  def search(scope, q)
    return scope if q.blank?

    scope.where(<<~SQL.squish, q: "%#{TripOccurrence.sanitize_sql_like(q.to_s.strip)}%")
      trip_occurrences.trip_label ILIKE :q OR trips.title ILIKE :q OR clients.name ILIKE :q OR vehicles.plate ILIKE :q OR occurrence_corrections.vehicle_plate ILIKE :q
      OR #{DRIVER_SQL} ILIKE :q OR operators.name ILIKE :q OR school_routes.label ILIKE :q OR schools.name ILIKE :q
    SQL
  end

  def label(key, value)
    case key
    when :client_id then labels(Client.with_discarded, :name)[value]
    when :vehicle_id then labels(Vehicle.with_discarded, :plate)[Integer(value.to_s, exception: false)] || value
    when :operator then { "own" => "Own fleet", "none" => "No vehicle" }[value] || labels(Operator.with_discarded, :name)[value.to_i]
    when :kind then value == "school_route" ? "School Route" : Trip::KIND_NAMES[value]
    when :outcome then TripHistory::OUTCOMES.dig(value, :label)
    when :on_time then TripHistory::ON_TIME[value]
    else value
    end
  end

  def labels(model, column) = (@labels ||= {})[model.name] ||= model.pluck(:id, column).to_h

  def date(key)
    @params[key].present? ? Date.iso8601(@params[key].to_s) : nil
  rescue Date::Error
    raise ApplicationService::Error, "#{key} must be a date (YYYY-MM-DD)"
  end
end
