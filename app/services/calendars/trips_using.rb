# Settings > Calendars > Trips Using This Calendar: the recurring trips that picked a calendar, with the runs the
# calendar (and public holidays) skip in a year.
module Calendars
  class TripsUsing < ApplicationService
    def initialize(calendar:, year:)
      @calendar = calendar
      @from = Date.new(year)
      @to = @from.end_of_year
    end

    def call
      trips = @calendar.trips.kept.recurring.includes(:client).order(:start_time, :title).to_a
      context = Context.for(@calendar.company, from: @from, to: @to)
      trips.map do |trip|
        skips = context.trip_skips(trip, @from, @to)
        { trip: trip.decorate, runs_skipped: skips.size, skipped: skips.map { |date, reason| { date:, reason: } } }
      end
    end
  end
end
