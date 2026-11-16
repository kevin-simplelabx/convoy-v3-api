# Convoy App › Household › Adults: add a photo (any adult), approve / decline Asked to Join (Admin).
module Api
  module V1
    module ConvoyApp
      class HouseholdMembersController < HouseholdBaseController
        before_action :require_admin!, only: %i[approve decline]

        # PATCH /app/household/members/:id { member: { photo (file) } } → the Household
        def update
          ::ConvoyApp::Households::SaveMemberPhoto.call(member: member, photo: params.dig(:member, :photo))
          render_household
        end

        # POST /app/household/members/:id/approve { relationship } → the Household ("<first> joined the <Family>")
        def approve
          ::ConvoyApp::Households::ReviewRequest.call(member:, approve: true, relationship: params[:relationship])
          render_household
        end

        # POST /app/household/members/:id/decline → the Household
        def decline
          ::ConvoyApp::Households::ReviewRequest.call(member:, approve: false)
          render_household
        end

        private

        def member = @member ||= household.members.find { it.id == params[:id].to_i } || raise(ActiveRecord::RecordNotFound)
      end
    end
  end
end
