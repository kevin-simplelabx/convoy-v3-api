module Api
  module V1
    class PlansController < BaseController
      before_action :require_company!
      before_action :load_school
      before_action -> { require_permission!("plans") }, only: [ :update, :update_draft ]

      # GET /api/v1/schools/:school_id/plans
      def show
        render json: Plan.for_school(@school).data
      end

      # PUT /api/v1/schools/:school_id/plans
      def update
        plan = Plan.for_school(@school)
        plan.update!(data: params[:_json] || [])
        render json: { ok: true }
      end

      # GET /api/v1/schools/:school_id/draft
      def show_draft
        render json: Draft.for_school(@school).data
      end

      # PUT /api/v1/schools/:school_id/draft
      def update_draft
        draft = Draft.for_school(@school)
        # Supports both JSON object and JSON array payloads
        data = params[:_json] || params.to_unsafe_h.except("school_id", "controller", "action", "plan", "draft", "format")
        draft.update!(data: data.presence)
        render json: { ok: true }
      end

      private

      def load_school
        @school = current_company.schools.find_by(id: params[:school_id])
        render_error("School not found", :not_found) unless @school
      end
    end
  end
end
