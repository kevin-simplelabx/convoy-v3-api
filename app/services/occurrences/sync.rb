# Makes a trip's stored occurrences match what the generator says, between two dates (rules in .notes/domains/occurrences.md):
# - a missing row is inserted (past dates too, so a backdated trip has its history);
# - a row that has started (starts_at <= now) is never changed;
# - a future row is updated when its inputs changed, keeping the fields a person changed (overridden_fields);
# - a future row the trip no longer makes is deleted, or marked removed when something hangs on it (issue, edits);
# - a date the calendar skips is a row with status skipped (and why), for Trip History.
# Runs under an advisory lock per trip. Returns the ids of the rows inserted, changed or removed.
module Occurrences
  class Sync < ApplicationService
    HORIZON_DAYS = 120
    BACKFILL_DAYS = 400
    TRIP_INCLUDES = [ :vehicle_slots, :time_changes, :price_cells, { runs: :slots, assignments: :slots } ].freeze

    def self.horizon = Date.current + HORIZON_DAYS

    ROUTE_INCLUDES = [ :vehicle_changes, :replacements, { plan: :school } ].freeze

    # routes: School Bus routes (SchoolRoute records or ids) to sync as well. Dates past the horizon are never stored.
    def initialize(trips: [], routes: [], from: nil, to: nil, now: Time.current)
      @trips = trips
      @routes = routes
      @from = from
      @to = to
      @now = now
    end

    def call
      trips = Trip.with_discarded.includes(*TRIP_INCLUDES).where(id: ids(@trips)).to_a
      routes = SchoolRoute.includes(*ROUTE_INCLUDES).where(id: ids(@routes)).to_a
      return [] if trips.empty? && routes.empty?

      to = [ @to || self.class.horizon, self.class.horizon ].min
      starts = trips.map(&:starts_on) + routes.map { |r| r.plan.effective_from }
      from = @from || [ starts.min, Date.current - BACKFILL_DAYS ].max
      return [] if from > to

      Partitions.ensure!(from, to)
      company = (trips.first || routes.first).company
      @fleet = Fleet.new
      ctx = Calendars::Context.for(company, from:, to:)
      index = ReplacementIndex.new(from, to)
      @generator = Generator.new(context: ctx, fleet: @fleet, replacements: index)
      @route_generator = RouteGenerator.new(context: ctx, fleet: @fleet, replacements: index)
      @bell = DriverApp::RunNotifications.new(now: @now)
      TripOccurrence.transaction do
        ids = trips.flat_map { |trip| sync_trip(trip, from, to) } + routes.flat_map { |route| sync_route(route, from, to) }
        @bell.flush
        ids
      end
    end

    private

    def ids(list) = Array(list).map { |x| x.respond_to?(:id) ? x.id : x }

    def sync_trip(trip, from, to)
      write(trip, TripOccurrence.where(trip_id: trip.id), from, to) do |existing|
        trip.kept? ? @generator.rows(trip, [ from, trip.starts_on ].max, to, existing:) : []
      end
    end

    def sync_route(route, from, to)
      write(route, TripOccurrence.where(school_route_id: route.id), from, to) do |existing|
        @route_generator.rows(route, from, to, existing:)
      end
    end

    # Compare the stored rows of one trip or route with what its generator says (the block) and write the difference.
    def write(source, scope, from, to)
      TripOccurrence.connection.execute("SELECT pg_advisory_xact_lock(#{lock_key(source)})")
      existing = scope.where(date: from..to).index_by(&:identity)
      desired = yield(existing)
      inserts = []
      changed = []

      desired.each do |row|
        occ = existing.delete(row.identity)
        if occ.nil? then inserts << row
        elsif future?(occ) && (occ.source_digest != row.digest || occ.removed?) then changed << update(occ, row)
        end
      end
      gone = existing.values.select { |occ| future?(occ) && !occ.removed? }
      kept = with_records(gone)
      gone.each { |occ| changed << remove(occ, kept.include?(occ.id)) }
      changed.compact + insert(source.company_id, inserts)
    end

    DRIVER_SEES = %i[driver_id operator_driver_id vehicle_id starts_at].freeze

    def future?(occ) = occ.starts_at > @now

    def insert(company_id, rows)
      return [] if rows.empty?

      now = Time.current
      records = rows.map do |r|
        r.to_h.merge(company_id:, status: r.skip_reason ? "skipped" : "scheduled", source_digest: r.digest, created_at: now, updated_at: now)
      end
      ids = TripOccurrence.insert_all!(records, returning: [ :id ]).rows.flatten
      @bell.inserted(company_id, ids.zip(rows))
      ids
    end

    # The generator already kept what a person set on this run (layer 3), so its row is written as it is.
    # A calendar change skips or brings back a run (unless a person set its status, e.g. cancelled it).
    # A new driver, bus or time shows the run as New again in the Driver app.
    def update(occ, row)
      attrs = row.to_h.except(:trip_id, :school_route_id, :date, :trip_run_id, :slot_no, :part)
      attrs[:status] = row.skip_reason ? "skipped" : "scheduled" if occ.removed? || ((occ.skipped? || occ.scheduled?) && !occ.overridden?(:status))
      attrs[:driver_seen_at] = nil if DRIVER_SEES.any? { |k| occ.public_send(k) != attrs[k] }
      @bell.updated(occ, attrs)
      occ.update_columns(attrs.merge(source_digest: row.digest, updated_at: Time.current))
      occ.id
    end

    # Rows with something on them stay, marked removed, for a person to look at (and come back with it when the run is made
    # again); others go. Something = an issue, a hand change, a cancel, or records pointing at the run (records).
    def remove(occ, has_records)
      @bell.removed(occ)
      if has_records || occ.issue? || occ.overridden_fields.any? || occ.cancelled?
        occ.update_columns(status: "removed", updated_at: Time.current)
      else
        occ.delete
      end
      occ.id
    end

    # Tables that point at a run and can be filled before it starts: the Driver app's Edit Route and actions (marks, stop
    # events), office notes and attendance, a driver report.
    RECORDS = [ OccurrencePassenger, OccurrenceStopEvent, DriverAppAction, OccurrenceNote, OccurrenceDriverReport, OccurrenceDisposal ].freeze

    # Ids of the runs that have records pointing at them.
    def with_records(runs)
      return Set.new if runs.empty?

      keys = runs.map { [ it.id, it.date ] }
      RECORDS.each_with_object(Set.new) do |model, found|
        found.merge(model.where([ :occurrence_id, :occurrence_date ] => keys).distinct.pluck(:occurrence_id))
      end
    end

    def lock_key(source) = Zlib.crc32("trip_occurrences:#{source.class.name}:#{source.id}")
  end
end
