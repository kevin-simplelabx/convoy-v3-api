# Convoy App › Account › Organisations: the employers and schools that found the person by work email. A link is an
# invitation (Accept / Not Me on Home or here), never made without a tap; the person cannot remove a link (the app says
# "ask the office"; the office removes it in Convoy OS).
module Api
  module V1
    module ConvoyApp
      class OrganisationsController < BaseController
        # GET /app/organisations → { invitations: [link], links: [link], unlinked: [{ identity_id, email, domain, company_guess }] }
        #   Looks for new matches first (a client may have added the domain after the email was verified).
        def index
          ::ConvoyApp::Links::Match.call(account: current_account)
          links = ::ConvoyApp::OrganisationLinks.call(account: current_account)
          render json: { data: { invitations: links.select { it[:status] == "invited" }, links: links.select { it[:status] == "accepted" },
                                 unlinked: unlinked(links) } }
        end

        # POST /app/organisations/:kind/:id/accept → the link
        def accept = answer(true)

        # POST /app/organisations/:kind/:id/decline (Not Me) → { declined: true }
        def decline = answer(false)

        private

        def answer(accept)
          ::ConvoyApp::Links::Answer.call(account: current_account, kind: params[:kind], id: params[:id], accept:)
          return render json: { data: { declined: true } } unless accept

          link = ::ConvoyApp::OrganisationLinks.call(account: current_account).find { it[:kind] == params[:kind] && it[:id] == params[:id].to_i }
          render json: { data: link }
        end

        # Work emails no organisation holds (no invited / accepted link): "Nothing linked yet" + Suggest Convoy.
        def unlinked(links)
          linked = links.pluck(:matched_email)
          current_account.identities.select { it.email? && it.work? && linked.exclude?(it.value) }.map do |identity|
            { identity_id: identity.id, email: identity.value, domain: identity.domain, company_guess: identity.domain.split(".").first.titleize }
          end
        end
      end
    end
  end
end
