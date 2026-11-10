# An AM plan's riders get its PUDO points (Stop Assignment), keeping the ones set by hand (port of Convoy OS promotePlan,
# which only runs when the plan starts: Adopt from today or earlier, or the daily job on a scheduled plan's start day;
# Convoy OS schedAdopt writes nothing, so Cancel has nothing to undo). riders_assigned_at is the lock: once per plan.
module Plans
  class AssignRiders < ApplicationService
    # AM plans in use today whose riders were not given their points yet (a scheduled plan that has reached its date).
    def self.due(today = Date.current)
      SchoolPlan.where(session: "am", riders_assigned_at: nil).running_between(today, today).find_each { call(it) }
    end

    def initialize(plan)
      @plan = plan
    end

    def call
      @plan.with_lock do
        next if @plan.riders_assigned_at || !@plan.session_am? || @plan.state != "current"

        school = @plan.school
        rows = SchoolRouteRider.joins(:stop).where(school_route_id: @plan.routes.select(:id)).pluck(:rid, "school_route_stops.stop_point_id")
        manual = school.rider_assignments.where(manual: true).pluck(:rid).to_set
        school.rider_assignments.where(manual: false).delete_all
        now = Time.current
        fresh = rows.reject { |rid, pid| manual.include?(rid) || pid.nil? }.map do |rid, pid|
          { company_id: school.company_id, school_id: school.id, rid:, stop_point_id: pid, school_plan_id: @plan.id, manual: false, created_at: now, updated_at: now }
        end
        RiderAssignment.insert_all!(fresh) if fresh.any?
        @plan.update!(riders_assigned_at: now)
      end
      @plan
    end
  end
end
