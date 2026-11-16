# Convoy App › Family invites sent to the signed-in person (Home shows them to Accept / Not Me). Works without a Family.
module Api
  module V1
    module ConvoyApp
      class HouseholdInvitationsController < BaseController
        # GET /app/household/invitations → [{ id, family, invited_by, relationship, invited_at }]
        def index
          rows = HouseholdMember.invitations_for(current_account).includes(:household, :invited_by).order(:id)
                                .select { it.household.kept? }
          render json: { data: rows.map { json(it) } }
        end

        # POST /app/household/invitations/:id/accept → the Household
        def accept
          ::ConvoyApp::Households::AnswerInvitation.call(member: invitation, accept: true)
          member = HouseholdMember.includes(household: [ { members: { app_account: :identities } }, { dependants: :dependant_guardians } ]).find(invitation.id)
          render_data(member.household, HouseholdBlueprint, viewer: member)
        end

        # POST /app/household/invitations/:id/decline  (Not Me)
        def decline
          ::ConvoyApp::Households::AnswerInvitation.call(member: invitation, accept: false)
          render json: { data: { declined: true } }
        end

        private

        def invitation = @invitation ||= HouseholdMember.invitations_for(current_account).includes(:household).find(params[:id])

        def json(member)
          { id: member.id, family: member.household.name, invited_by: member.invited_by&.display_name, relationship: member.relationship,
            invited_at: member.updated_at }
        end
      end
    end
  end
end
