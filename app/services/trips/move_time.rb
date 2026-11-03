# Save Time over a whole trip (a one-off trip, or from the first run of a recurring trip with no time changes yet): the
# trip itself moves, not one run. Its start and end and every stop time (on a shuttle: that run's times) move by the
# same minutes; the flight time stays. Shifts set on its runs by Today Only are dropped, so each run takes the new time.
# Goes through Trips::Save: the trip's own checks apply and its runs are synced.
module Trips
  class MoveTime < ApplicationService
    def initialize(trip:, minutes:, user:, trip_run: nil)
      @trip = trip
      @minutes = minutes
      @user = user
      @run = trip_run
    end

    def call
      raise Error, "Pick a different time" if @minutes.zero?

      Trip.transaction do
        drop_shifts!
        Save.call(trip: @trip, attributes: @run ? run_attributes : trip_attributes, user: @user)
      end
    end

    private

    def trip_attributes
      start = @trip.start_time + @minutes
      raise Error, "Pick a time on the same day" unless (0...1440).cover?(start)

      stops = @trip.stops.select(&:scheduled_time).map { { id: it.id, scheduled_time: it.scheduled_time + @minutes } }
      { start_time: start, end_time: @trip.end_time + @minutes, stops_attributes: stops }
    end

    def run_attributes
      raise Error, "Pick a time on the same day" unless (0...1440).cover?(@run.start_time + @minutes)

      times = @run.stop_minutes
      run = if times.any? then { times: times.map { it && Clock.hm(it + @minutes) } }
      else { start_time: @run.start_time + @minutes, end_time: @run.end_time + @minutes }
      end
      { runs_attributes: [ run.merge(id: @run.id) ] }
    end

    def drop_shifts!
      runs = TripOccurrence.where(trip: @trip).where(starts_at: Time.current..).where("'shift_minutes' = ANY(overridden_fields)")
      runs = runs.where(trip_run: @run) if @run
      runs.each do |occ|
        occ.update!(shift_minutes: 0, overridden_fields: occ.overridden_fields - %w[shift_minutes], source_digest: nil)
      end
    end
  end
end
