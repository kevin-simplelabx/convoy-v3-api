# Share Form answers waiting below the link (Review and Add = POST /vehicles/external with submission_id, or Dismiss).
module Api
  module V1
    class ExternalVehicleSubmissionsController < BaseController
      def index
        authorize ExternalVehicleSubmission
        scope = policy_scope(ExternalVehicleSubmission).where(status: params[:status].presence || "pending").order(created_at: :desc)
        render_page scope, ExternalVehicleSubmissionBlueprint
      end

      def dismiss
        submission = authorize policy_scope(ExternalVehicleSubmission).pending.find(params[:id]), :update?
        submission.decide!(:dismissed, user: current_user)
        render_data submission, ExternalVehicleSubmissionBlueprint
      end
    end
  end
end
