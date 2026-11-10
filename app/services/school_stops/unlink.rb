# Unlink a stop from a school (the school's hand links and the riders assigned to the stop's points go too), as the HTML
# does (`unlinkStop`; it only warns when riders use the stop). Returns how many riders were unassigned.
module SchoolStops
  class Unlink < ApplicationService
    def initialize(school, stop)
      @school = school
      @stop = stop
    end

    def call
      ss = @school.school_stops.find_by!(stop_id: @stop.id)
      point_ids = @stop.all_points.select(:id)
      SchoolStop.transaction do
        @school.rider_point_links.where(stop_point_id: point_ids).delete_all
        unassigned = @school.rider_assignments.where(stop_point_id: point_ids).destroy_all.size
        ss.destroy!
        unassigned
      end
    end
  end
end
