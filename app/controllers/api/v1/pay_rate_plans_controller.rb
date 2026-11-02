# HR > Rate Plans: list, plan (periods, times, rates), Save / Save and Lock (the whole plan), Lock / Unlock, Delete,
# and the Coverage grid.
module Api
  module V1
    class PayRatePlansController < BaseController
      def index
        authorize PayRatePlan
        plans = policy_scope(PayRatePlan).kept.includes(:periods, :locked_by).order(:name)
        render_list plans, PayRatePlanBlueprint, schemes: used_by
      end

      def show
        render_plan authorize(find_plan)
      end

      # POST /pay/rate_plans { rate_plan: {...}, lock: true }
      def create
        authorize PayRatePlan
        plan = PayRatePlans::Save.call(plan: PayRatePlan.new, params: plan_params, user: current_user, lock: lock?)
        render_plan plan, status: :created
      end

      def update
        plan = authorize find_plan
        render_plan PayRatePlans::Save.call(plan:, params: plan_params, user: current_user, lock: lock?, admin: policy(plan).admin?)
      end

      def destroy
        plan = authorize find_plan
        plan.ensure_unlocked!(admin: policy(plan).admin?)
        names = Array(used_by[plan.id])
        raise ApplicationService::Error, "Used by #{names.to_sentence}. Pick another rate plan there first" if names.any?

        plan.discard!
        plan.audits.create!(action: "destroy", audited_changes: { "name" => plan.name })
        head :no_content
      end

      def lock
        plan = authorize find_plan
        plan.lock!(current_user) unless plan.locked?
        render_plan plan
      end

      def unlock
        plan = authorize find_plan
        plan.unlock! if plan.locked?
        render_plan plan
      end

      # GET /pay/rate_plans/:id/coverage — 8 rows (Mon..Sun, PH) × 48 half hours: the period paying each cell.
      def coverage
        render json: { data: Pay::Coverage.call(plan: authorize(find_plan, :show?)) }
      end

      private

      def find_plan = policy_scope(PayRatePlan).kept.includes(:plan_vehicle_types, :locked_by, periods: %i[ranges rates]).find(params[:id])

      def lock? = ActiveModel::Type::Boolean.new.cast(params[:lock]) || false

      def plan_params
        params.expect(rate_plan: [ :name, :description, { vehicle_type_ids: [] },
                                   { periods: [ [ :name, :takes_priority, { days: [] }, { ranges: [ %i[start_time end_time] ] },
                                                  { rates: [ %i[vehicle_type_id per_trip per_hour] ] } ] ] } ])
      end

      # { plan_id => [scheme names] }
      def used_by
        PayScheme.kept.pluck(:pay_rate_plan_id, :name).group_by(&:first).transform_values { |v| v.map(&:last) }
      end

      def render_plan(plan, status: :ok)
        render_data find_plan_for(plan), PayRatePlanBlueprint, view: :detail, status:
      end

      def find_plan_for(plan) = PayRatePlan.includes(:plan_vehicle_types, :locked_by, periods: %i[ranges rates]).find(plan.id)
    end
  end
end
