# Archive a stop (only when no school uses it). Riders still assigned to its points (left by an earlier unlink) are
# unassigned in the same transaction. Returns how many.
module Stops
  class Archive < ApplicationService
    def initialize(stop)
      @stop = stop
    end

    def call
      raise Error, "Unlink #{@stop.code} from every school first" if @stop.school_stops.any?

      Stop.transaction do
        unassigned = RiderAssignment.where(stop_point_id: @stop.all_points.select(:id)).destroy_all.size
        @stop.discard!
        unassigned
      end
    end
  end
end
