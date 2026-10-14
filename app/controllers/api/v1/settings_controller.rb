module Api
  module V1
    class SettingsController < BaseController
      before_action :require_company!

      # GET /api/v1/settings
      def show
        render json: current_company.settings || {}
      end

      # PUT /api/v1/settings
      def update
        patch = params.to_unsafe_h.except("controller", "action", "format")
        merged = (current_company.settings || {}).merge(patch)
        current_company.update!(settings: merged)
        render json: merged
      rescue ActiveRecord::RecordInvalid => e
        render_error(e.record.errors.full_messages.first)
      end
    end
  end
end
