# Convoy App › Household › Authorised Guardians: who may receive each child at drop-off. Any adult can switch.
module Api
  module V1
    module ConvoyApp
      class HouseholdGuardiansController < HouseholdBaseController
        # GET /app/household/guardians → [{ id, name, first_name, can_receive, of, adults: [{ member_id, name, photo, relationship,
        #   status, state, allowed, can_receive }] }]   state: always (Mother / Father, locked) | on | off | pending | needs_photo
        def index
          render json: { data: ::ConvoyApp::Households::GuardianBoard.call(household:) }
        end

        # PUT /app/household/dependants/:dependant_id/guardians/:member_id { allowed: true | false } → that child, as in index
        def update
          child = household.dependants.find { it.id == params[:dependant_id].to_i } or raise ActiveRecord::RecordNotFound
          member = household.members.find { it.id == params[:member_id].to_i && (it.active? || it.invited?) } or raise ActiveRecord::RecordNotFound
          ::ConvoyApp::Households::SetGuardian.call(dependant: child, member:, allowed: params.require(:allowed))
          render json: { data: ::ConvoyApp::Households::GuardianBoard.call(household: reloaded, dependant_id: child.id).first }
        end

        private

        def reloaded = Household.includes(members: { app_account: :identities }, dependants: []).find(household.id)
      end
    end
  end
end
