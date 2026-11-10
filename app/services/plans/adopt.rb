# Adopt Plan from a date (the 1st of this month or later, not before the current plan's start). The plan runs on the
# Scheduler from that date — Current when the date has come, Scheduled before — and the plan of the session in use then
# ends the day before (an earlier scheduled plan of the session is cancelled); from the very day the current plan started,
# that plan is taken out of use, as if it never ran. An AM plan gives its riders their PUDO points (Plans::AssignRiders)
# when it starts: at once from today or earlier, else the daily job on its start day (Convoy OS: promotePlan writes
# them, schedAdopt does not). Route Charges of the plan it replaces move to the best-matching new routes (status
# check). Cancel: a scheduled plan goes back to draft and the plan it would replace runs on (nothing to undo).
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
      if running && @from < running.effective_from
        raise Error, "#{running.name} was only adopted on #{running.effective_from.strftime('%-d %b %Y')}. Pick that day or later"
      end
      current = siblings.find { it.effective_from < @from && (it.effective_to.nil? || it.effective_to >= @from) }
      replaced = running if running&.effective_from == @from

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
        if replaced
          touched << replaced
          replaced.update!(in_use: false, effective_to: nil, adopted_at: nil, adopted_by: nil)
        end
        @plan.update!(in_use: true, effective_from: @from, effective_to: nil, adopted_at: Time.current, adopted_by: @user, riders_assigned_at: nil)
        (current || replaced)&.then { RouteCharges.carry(it, @plan, @from) }
        AssignRiders.call(@plan) if @from <= Date.current
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
  end
end
