# The days of one route as a rider sees them: service, no service (a public holiday or the client's day off = a skipped
# occurrence, else a day the trip does not run) or changed times (the day's runs start earlier / later than the timing, from
# the calendar or an Every Run From Today change), and which runs have another bus, a relief driver or are cancelled.
#   Days.new(trip, from, to).day(date) -> Day
# Reads occurrences once for the range (+ 14 days to find "Service resumes"). Run inside the company.
module ConvoyApp
  module Shuttles
    class Days
      Day = Data.define(:date, :state, :reason, :resumes_on, :shifts, :changes)

      attr_reader :occurrences

      def initialize(trip, from, to)
        @trip = trip
        @from = from
        @to = to
        @runs = trip.runs.index_by(&:id)
        rows = TripOccurrence.where(trip_id: trip.id, date: from..(to + RESUME_DAYS)).where.not(status: "removed").includes(:replacement, :school_route, :vehicle)
                             .order(:date, :starts_at, :slot_no, :part).to_a
        rows.each do |occ| # the route as loaded (stops, runs and their times), not read again per run
          occ.association(:trip).target = trip
          occ.association(:trip_run).target = @runs[occ.trip_run_id] if occ.trip_run_id
        end
        @by_date = rows.group_by(&:date)
        @occurrences = @by_date
      end

      def day(date)
        rows = @by_date[date] || []
        live = rows.reject(&:skipped?)
        return off(date, rows) if live.empty?

        shifts = live.filter_map { |o| shift = o.start_time - @runs[o.trip_run_id].start_time and shift.nonzero? && { direction: @runs[o.trip_run_id].direction, minutes: shift } }.uniq
        changes = live.filter_map { |o| change(o)&.dig(:kind) }.uniq
        Day.new(date:, state: shifts.any? ? "changed" : "service", reason: nil, resumes_on: nil, shifts:, changes:)
      end

      def strip(from = @from, count = STRIP_DAYS) = (from...(from + count)).map { day(it) }

      # The occurrences of a date that run (not skipped).
      def runs_on(date) = (@by_date[date] || []).reject(&:skipped?)

      def change(occ)
        run = @runs[occ.trip_run_id]
        Change.of(occ, trip: @trip, regular_vehicle_id: Occurrences::Regular.vehicle_id(@trip, run, occ.slot_no, occ.date))
      end

      private

      def off(date, rows)
        Day.new(date:, state: "no_service", reason: reason(date, rows), resumes_on: resumes_on(date), shifts: [], changes: [])
      end

      def reason(date, rows)
        skipped = rows.find(&:skipped?)
        return skipped.skip_reason.presence || "No service" if skipped
        return "Not running yet" if date < @trip.starts_on
        return "Service ended" if @trip.ends_on && date > @trip.ends_on

        @trip.days.include?(date.wday) ? "No service" : (date.saturday? || date.sunday? ? "Weekend" : "Not a service day")
      end

      # The first day after with a run, within RESUME_DAYS (nil when none yet).
      def resumes_on(date)
        (1..RESUME_DAYS).map { date + it }.find { |d| d <= @to + RESUME_DAYS && runs_on(d).any? }
      end
    end
  end
end
