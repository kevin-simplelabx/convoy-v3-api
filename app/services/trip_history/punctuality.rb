# Keeps trip_occurrences.max_delay_minutes: the latest arrival against plan over the stops reached (corrected times
# first, then recorded ones), or nil when no arrival is known. On Time compares it with the company's on_time_minutes.
# Run after stop events arrive (Telematics::Record) and after Correct Record. A cached figure, so update_columns
# (no lock_version bump, no audit).
module TripHistory
  class Punctuality < ApplicationService
    def initialize(occ)
      @occ = occ
    end

    def call
      @occ.stop_events.reset
      @occ.correction&.stops&.reset
      delays = TripHistory.stop_record(@occ, 0).filter_map { |s| s[:delay_minutes] }
      @occ.update_columns(max_delay_minutes: delays.max)
      delays.max
    end
  end
end
