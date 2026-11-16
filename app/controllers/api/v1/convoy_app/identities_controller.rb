# Convoy App › Account › Mobile and Emails: every verified mobile and email (personal or work; any of them signs in),
# what each is used for, and adding one with a code (Add Work Email, Add / Change Mobile, Add / Change Personal Email,
# Verify Again of a work email). A verified work email also answers which organisations found it (`invitations`).
module Api
  module V1
    module ConvoyApp
      class IdentitiesController < BaseController
        skip_before_action :require_profile!

        # GET /app/identities
        def index = render_identities

        # POST /app/identities/code { kind (mobile|email), value, tag (personal|work), replace (Change) }
        #   → { kind, value, display, tag, replace }
        def code
          render json: { data: ::ConvoyApp::Identities::SendCode.call(account: current_account, ip: request.remote_ip, **input) }
        end

        # POST /app/identities/verify { kind, value, tag, replace, code } → { identity, outcome, identities, invitations }
        #   invitations: links (Organisations shape) this work email found and the person has not answered; [] = nothing linked yet
        def verify
          result = ::ConvoyApp::Identities::Verify.call(account: current_account, code: params.require(:code), **input)
          current_account.reload # the list changed under this same object
          render json: { data: { outcome: result[:outcome], identity: identity_json(result[:identity]), identities: identities_json,
                                    invitations: invitations_for(result[:identity]) } }
        end

        # DELETE /app/identities/:id
        def destroy
          ::ConvoyApp::Identities::Remove.call(identity: current_account.identities.find(params[:id]))
          current_account.reload # Remove loaded the list on this same object before the delete
          render_identities
        end

        private

        def input = { kind: params[:kind], value: params[:value], tag: params[:tag], replace: params[:replace] }

        def render_identities = render(json: { data: identities_json })

        def uses = @uses ||= ::ConvoyApp::Identities::Uses.call(account: current_account)

        def invitations_for(identity)
          return [] unless identity.email? && identity.work?

          ::ConvoyApp::OrganisationLinks.call(account: current_account).select { it[:status] == "invited" && it[:matched_email] == identity.value }
        end

        def identities_json = current_account.identities.map { identity_json(it) }

        def identity_json(identity) = AppIdentityBlueprint.render_as_hash(identity, uses: uses[identity.id] || [])
      end
    end
  end
end
