# External Vehicles > Share Form: the company's link for hired drivers (made on first use) and New link.
module Api
  module V1
    class ExternalShareLinksController < BaseController
      def show
        authorize ExternalVehicleShareLink, :show?
        render json: { data: link_json(ExternalVehicleShareLink.current!(user: current_user.convoy_admin? ? nil : current_user)) }
      end

      # The old link stops working; answers already sent are kept.
      def reset
        authorize ExternalVehicleShareLink, :create?
        render json: { data: link_json(ExternalVehicleShareLink.reset!(user: current_user)) }, status: :created
      end

      private

      def link_json(link)
        { token: link.token, created_at: link.created_at,
          api_path: Rails.application.routes.url_helpers.api_v1_public_share_form_path(link.token) }
      end
    end
  end
end
