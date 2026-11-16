# Base for the Convoy App shuttle screens. The employer in the path is one of the person's accepted, not paused staff links
# (`employers/:employer_id` = the link id, the `id` of an employer in `GET /app/shuttles`); any other id, a paused or removed
# link, or a company that is not active is 404, so nothing of an employer shows without a live link.
module Api
  module V1
    module ConvoyApp
      class ShuttleBaseController < BaseController
        private

        def employer = @employer ||= ::ConvoyApp::Shuttles.employer!(current_account, params[:employer_id])
      end
    end
  end
end
