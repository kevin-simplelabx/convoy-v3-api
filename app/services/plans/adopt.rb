# Adopt Plan from a date (the 1st of this month or later, not before the current plan's start). The plan runs on the
# Scheduler from that date — Current when the date has come, Scheduled before — and the plan of the session in use then
# ends the day before (an earlier scheduled plan of the session is cancelled). Adopting an AM plan assigns its riders'
# PUDO points (Stop Assignment), keeping the ones set by hand. Route Charges of the plan it replaces move to the
# best-matching new routes (status check). Cancel: a scheduled plan goes back to draft and the
# plan it would replace runs on.
module Plans
  class Adopt < ApplicationService
    def initialize(plan, from:, user:)
      @plan = plan
      @from = from
      @user = user
    end

    def call
      raise Error, "Pick the date the plan starts" unless @from
      raise Error, "The plan has no routes" if @plan.routes.empty?
      raise Error, "This plan is already adopted" if @plan.in_use
      raise Error, "Pick a date from the 1st of this month" if @from < Date.current.beginning_of_month

      siblings = @plan.school.plans.where(session: @plan.session, in_use: true).where.not(id: @plan.id).to_a
      running = siblings.find { it.state == "current" }
      if running && @from <= running.effective_from
        raise Error, "Pick a date after #{running.effective_from.strftime('%-d %b %Y')}, when the current plan started"
      end
      current = siblings.find { it.effective_from < @from && (it.effective_to.nil? || it.effective_to >= @from) }

      touched = []
      SchoolPlan.transaction do
        siblings.select { it.effective_from > Date.current && it.effective_from >= @from }.each do |later|
          touched << later
          later.update!(in_use: false, adopted_at: nil, adopted_by: nil)
        end
        if current
          touched << current
          current.update!(effective_to: @from - 1)
        end
        @plan.update!(in_use: true, effective_from: @from, effective_to: nil, adopted_at: Time.current, adopted_by: @user)
        RouteCharges.carry(current, @plan, @from) if current
        assign_riders if @plan.session_am?
      end
      Plans.resync(@plan, *touched)
      @plan
    end

    def self.cancel(plan)
      raise Error, "Only a scheduled plan can be cancelled" unless plan.state == "scheduled"

      before = plan.school.plans.where(session: plan.session, in_use: true, effective_to: plan.effective_from - 1).first
      SchoolPlan.transaction do
        plan.update!(in_use: false, adopted_at: nil, adopted_by: nil)
        before&.update!(effective_to: nil)
      end
      Plans.resync(plan, before)
      plan
    end

    private

    def assign_riders
      school = @plan.school
      rows = SchoolRouteRider.joins(:stop).where(school_route_id: @plan.routes.select(:id)).pluck(:rid, "school_route_stops.stop_point_id")
      manual = school.rider_assignments.where(manual: true).pluck(:rid).to_set
      school.rider_assignments.where(manual: false).delete_all
      now = Time.current
      fresh = rows.reject { |rid, pid| manual.include?(rid) || pid.nil? }.map do |rid, pid|
        { company_id: school.company_id, school_id: school.id, rid:, stop_point_id: pid, school_plan_id: @plan.id, manual: false, created_at: now, updated_at: now }
      end
      RiderAssignment.insert_all!(fresh) if fresh.any?
    end
  end
end
