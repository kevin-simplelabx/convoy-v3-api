# School Bus › Route Plans: a school's plans of a session, one plan, Draw Routes (an empty plan to draw by hand), rename
# / dates, delete a draft, comments, and Compare Plans (routing service /diff).
module Api
  module V1
    class SchoolPlansController < BaseController
      INCLUDES = [ :school, :created_by, :comments, { routing_run: [] }, { routes: [ :attendant, :prices, :charges, { vehicle_changes: :vehicle, stops: %i[riders stop stop_point] } ] } ].freeze

      # GET /schools/:school_id/plans?session=am
      def index
        school = find_school
        authorize Stop, :index?
        list = school.plans.includes(:school, :created_by, :comments, :routes).order(created_at: :desc, id: :desc)
        list = list.where(session: params[:session]) if params[:session].present?
        render_list list, SchoolPlanBlueprint
      end

      # POST /schools/:school_id/plans { session } — Draw Routes: an empty plan to draw routes on.
      def create
        school = find_school
        authorize Stop, :update?
        session = params.require(:session)
        plan = school.plans.create!(name: Plans.next_name(school, session), session:, effective_from: Date.current, in_use: false, source: "manual",
                                    created_by: current_user)
        render_data find(plan.id), SchoolPlanBlueprint, view: :detail, status: :created
      end

      def show
        authorize Stop, :index?
        render_data find, SchoolPlanBlueprint, view: :detail
      end

      # PATCH /plans/:id { plan: { name, effective_from, effective_to } }
      def update
        authorize Stop, :update?
        plan = find
        plan.update!(params.expect(plan: %i[name effective_from effective_to]))
        AcademicYears.resync(plan.school) if plan.in_use && plan.saved_changes.keys.intersect?(%w[effective_from effective_to])
        render_data find, SchoolPlanBlueprint, view: :detail
      end

      def destroy
        authorize Stop, :update?
        Plans::Destroy.call(SchoolPlan.where(school: policy_scope(School)).find(params[:id]))
        head :no_content
      end

      # POST /plans/:id/comments { body }
      def comment
        authorize Stop, :update?
        plan = find
        plan.comments.create!(body: params.require(:body).to_s.strip, user: current_user)
        render_data find, SchoolPlanBlueprint, view: :detail, status: :created
      end

      # DELETE /plans/:id/comments/:comment_id
      def uncomment
        authorize Stop, :update?
        find.comments.find(params[:comment_id]).destroy!
        head :no_content
      end

      # POST /plans/:id/adopt { from }
      def adopt
        authorize Stop, :update?
        from = params[:from].present? ? Date.iso8601(params[:from]) : nil
        Plans::Adopt.call(SchoolPlan.where(school: policy_scope(School)).find(params[:id]), from:, user: current_user)
        render_data find, SchoolPlanBlueprint, view: :detail
      rescue Date::Error
        raise ApplicationService::Error, "Pick the date the plan starts"
      end

      # POST /plans/:id/cancel_adoption — a scheduled plan back to draft.
      def cancel_adoption
        authorize Stop, :update?
        Plans::Adopt.cancel(SchoolPlan.where(school: policy_scope(School)).find(params[:id]))
        render_data find, SchoolPlanBlueprint, view: :detail
      end

      # GET /plans/:id/compare?with=:other_id
      def compare
        authorize Stop, :index?
        plan = find
        other = find(params.require(:with))
        diff = Routing::Client.current.diff(Plans::EngineShape.call(plan), Plans::EngineShape.call(other))
        render json: { data: diff.merge("a" => plan.name, "b" => other.name) }
      rescue Routing::Client::Unavailable => e
        raise ApplicationService::Error, "The routing service is not available (#{e.message})"
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])
      def find(id = params[:id]) = SchoolPlan.where(school: policy_scope(School)).includes(*INCLUDES).find(id)
    end
  end
end
