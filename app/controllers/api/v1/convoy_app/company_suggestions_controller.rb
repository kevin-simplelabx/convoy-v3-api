# Convoy App › Suggest Convoy to My Company (a work email that links to nothing): Tell Convoy → a Company Lead for
# Convoy Admin; the person is named only when they agree.
module Api
  module V1
    module ConvoyApp
      class CompanySuggestionsController < BaseController
        # POST /app/company_suggestions { identity_id, company_name, contact, named }
        def create
          identity = current_account.identities.find(params.require(:identity_id))
          lead = ::ConvoyApp::SuggestCompany.call(account: current_account, identity:, company_name: params[:company_name],
                                                  contact: params[:contact], named: params[:named])
          render json: { data: { id: lead.id, company_name: lead.company_name, domain: lead.domain, named: lead.named_name.present? } }, status: :created
        end
      end
    end
  end
end
