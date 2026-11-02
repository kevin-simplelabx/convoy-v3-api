# The replacements that may touch runs between two dates, loaded once; finds the one for a run.
module Occurrences
  class ReplacementIndex
    def initialize(from, to)
      @list = Replacement.overlapping(from, to).order(:created_at).to_a
      @runs = @list.select(&:for_run?).index_by { |r| [ r.trip_id, r.school_route_id, r.run_date, r.trip_run_id, r.slot_no ] }
      @ranges = @list.select(&:for_range?).group_by(&:original_vehicle_id)
    end

    # A run replacement wins; else the latest range one on the run's bus.
    def for(trip_id, date, trip_run_id, slot_no, vehicle_id, school_route_id: nil)
      @runs[[ trip_id, school_route_id, date, trip_run_id, slot_no ]] ||
        (@ranges[vehicle_id] || []).reverse.find { |r| (r.starts_on..r.ends_on).cover?(date) }
    end
  end
end
