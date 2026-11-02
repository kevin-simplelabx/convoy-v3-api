# The Trips page: runs between two dates (at most MAX_DAYS) with search, type and operator filters, status chips and sort.
# Params: from, to, q, kind, operator (own | none | <operator id>), status_group, sort (date | date_desc).
class RunSearch
  MAX_DAYS = 183
  STATUS_GROUPS = %w[unassigned assigned live completed cancelled].freeze
  INCLUDES = [ *OccurrenceWindow::INCLUDES, :operator, :client, { trip: { vehicle_requirements: :vehicle_type } } ].freeze

  # Same order as TripOccurrence#status_group.
  STATUS_SQL = <<~SQL.squish.freeze
    CASE WHEN trip_occurrences.status = 'cancelled' THEN 'cancelled'
         WHEN trip_occurrences.status = 'completed' OR trip_occurrences.ended_at IS NOT NULL OR trip_occurrences.ends_at <= :now THEN 'completed'
         WHEN trip_occurrences.vehicle_id IS NULL THEN 'unassigned'
         WHEN trip_occurrences.starts_at <= :now THEN 'live'
         ELSE 'assigned' END
  SQL

  attr_reader :from, :to

  def initialize(scope, params, now: Time.current)
    @scope = scope
    @params = params
    @now = now
    @from = parse_date(:from)
    @to = parse_date(:to)
    raise ApplicationService::Error, "Pick a From date on or before the To date" if @to < @from
    raise ApplicationService::Error, "Trips show up to 6 months at a time" if (@to - @from).to_i >= MAX_DAYS
  end

  def call
    s = filtered
    s = s.where("#{status_sql} = ?", @params[:status_group]) if STATUS_GROUPS.include?(@params[:status_group])
    dir = @params[:sort] == "date_desc" ? :desc : :asc
    s.includes(*INCLUDES).order(starts_at: dir, trip_label: :asc)
  end

  # Chip counts (every filter but the status), and the types and operators found in the dates for the filter menus.
  def facets
    counts = filtered.group(Arel.sql(status_sql)).count
    in_range = in_dates
    operator_ids = in_range.where.not(operator_id: nil).distinct.pluck(:operator_id)
    {
      counts: { all: counts.values.sum }.merge(STATUS_GROUPS.index_with { |g| counts[g].to_i }),
      kinds: in_range.distinct.pluck(:kind).sort,
      operators: Operator.with_discarded.where(id: operator_ids).order(:name).map { |o| { id: o.id, name: o.name, kind: o.kind } }
    }
  end

  private

  def in_dates = @scope.visible.between(@from, @to)

  def filtered
    s = in_dates
    s = s.where(kind: @params[:kind]) if @params[:kind].present?
    s = by_operator(s, @params[:operator].to_s) if @params[:operator].present?
    search(s, @params[:q])
  end

  def by_operator(scope, operator)
    case operator
    when "own" then scope.where.not(vehicle_id: nil).where(operator_id: nil)
    when "none" then scope.where(vehicle_id: nil)
    else scope.where(operator_id: operator)
    end
  end

  # Trip ID, title, Service For, client, stops, plate, driver, operator, school route.
  def search(scope, q)
    return scope if q.blank?

    like = "%#{TripOccurrence.sanitize_sql_like(q.to_s.strip)}%"
    scope.left_joins(:trip, :vehicle, :driver, :operator_driver, :operator, :client, school_route: { plan: :school }).where(<<~SQL.squish, q: like)
      trip_occurrences.trip_label ILIKE :q OR trips.title ILIKE :q OR trips.service_for ILIKE :q OR clients.name ILIKE :q
      OR vehicles.plate ILIKE :q OR drivers.name ILIKE :q OR operator_drivers.name ILIKE :q OR trip_occurrences.driver_name ILIKE :q
      OR vehicles.driver_name ILIKE :q OR operators.name ILIKE :q OR school_routes.label ILIKE :q OR schools.short_name ILIKE :q OR schools.name ILIKE :q
      OR EXISTS (SELECT 1 FROM trip_stops ts WHERE ts.trip_id = trip_occurrences.trip_id AND ts.name ILIKE :q)
    SQL
  end

  def status_sql = TripOccurrence.sanitize_sql_array([ STATUS_SQL, { now: @now } ])

  def parse_date(key)
    Date.iso8601(@params.require(key).to_s)
  rescue Date::Error
    raise ApplicationService::Error, "#{key} must be a date (YYYY-MM-DD)"
  end
end
