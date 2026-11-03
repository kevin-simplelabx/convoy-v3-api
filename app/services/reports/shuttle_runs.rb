# The runs of a Corporate Shuttle trip in a date range, with what happened at each stop (recorded stop events, corrected
# by Correct Record). Each stop gets a status against its timetable: ok (from `early` minutes before to `late` minutes
# after), early (well before: fine, counts on time), late, edep (left a pick-up before the timetable: counts against),
# skip (not reached). Runs with no stop data are left out (nothing recorded yet).
module Reports
  class ShuttleRuns < ApplicationService
    EARLY = 5

    Run = Struct.new(:occ, :timing, :date, :seats, :riders, :stops, keyword_init: true)

    def initialize(trip:, from:, to:, late: 3, today: Date.current)
      @trip = trip
      @from = from
      @to = [ to, today ].min
      @late = late
    end

    def call
      return [] if @to < @from

      TripOccurrence.where(trip: @trip).between(@from, @to).where.not(status: %w[cancelled removed skipped])
                    .includes(:vehicle, :school_route, :stop_events, trip_run: :times, correction: :stops, trip: :stops).chronological
                    .filter_map { |occ| build(occ) }
    end

    private

    def build(occ)
      recorded = TripHistory.recorded_stops(occ)
      planned = TripHistory.planned_stops(occ)
      stops = planned.each_with_index.map do |s, i|
        fixed = occ.correction&.stop(s[:position])
        rec = recorded[s[:position]] || {}
        val = ->(f) { fixed && !fixed.public_send(f).nil? ? fixed.public_send(f) : rec[f] }
        arrived = val.(:arrived_at)
        departed = val.(:departed_at)
        last = i == planned.size - 1
        { position: s[:position], name: s[:name], planned: s[:planned_minute], arrived:, departed:, boarded: last ? 0 : val.(:boarded).to_i,
          status: status(s[:planned_minute], arrived, departed, last, rec[:skipped]), amended: fixed.present? }
      end
      return nil if stops.none? { |s| s[:arrived] || s[:boarded].positive? }

      Run.new(occ:, timing: timing(occ), date: occ.date, seats: occ.vehicle&.seats || 23, riders: stops.sum { |s| s[:boarded] }, stops:)
    end

    # One timing = one run of the timetable: { key, direction, position, dep }.
    def timing(occ)
      run = occ.trip_run
      { key: run ? "#{run.direction}-#{run.position}" : "#{occ.start_time}", direction: run&.direction || 1, position: run&.position || 0,
        dep: Clock.hm(run&.start_time || occ.start_time) }
    end

    def status(planned, arrived, departed, last, skipped)
      return "skip" if arrived.nil? || skipped
      return "ok" if planned.nil?
      return "edep" if !last && departed && departed < planned
      return "late" if arrived - planned > @late
      return "early" if planned - arrived > EARLY

      "ok"
    end
  end
end
