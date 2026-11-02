# Profile dialog (account menu): your own picture, display name and mobile. Name and email are set by an Admin in Users.
module Api
  module V1
    class ProfilesController < BaseController
      # GET /api/v1/profile
      def show
        render_data authorize(current_user, :profile?), UserBlueprint
      end

      # PATCH /api/v1/profile (multipart when a picture is sent) { profile: { display_name, mobile, avatar, remove_avatar } }
      def update
        user = authorize(current_user, :profile?)
        user.update!(params.expect(profile: policy(user).permitted_attributes_for_profile))
        render_data user, UserBlueprint
      end
    end
  end
end
