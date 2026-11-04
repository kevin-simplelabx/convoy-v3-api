# Base for the Client Portal after sign-in: the client account (client user) picked for the token, checked on every
# request (still kept, client not deleted, company not suspended: PortalAccount#accounts), else 422 pick_account.
# Work runs in that client's company (tenant) and timezone, is audited as the client user, and is authorised with
# Pundit policies under Portal:: (the user is the client user).
module Api
  module V1
    module Portal
      class AppController < BaseController
        include Pundit::Authorization

        before_action :authenticate_portal!
        before_action :require_client_user!
        around_action :in_client_company
        after_action :verify_authorized

        private

        def current_client_user
          return @current_client_user if defined?(@current_client_user)

          id = current_portal_jwt&.client_user_id
          @current_client_user = id && current_account.accounts.find { |u| u.id == id }
        end

        def current_client = current_client_user.client

        # Audits and the forbidden message read current_user; Pundit reads pundit_user.
        def current_user = current_client_user
        def pundit_user = current_client_user

        def require_client_user!
          return if current_client_user

          raise ApplicationService::Error.new("Pick an organisation first", code: "pick_account")
        end

        def in_client_company(&)
          company = current_client.company
          Audited.audit_class.as_user(current_client_user) do
            ActsAsTenant.with_tenant(company) { Time.use_zone(company.timezone || Time.zone, &) }
          end
        end

        def authorize_portal(record, query = nil) = authorize([ :portal, record ], query)

        def render_data(object, blueprint, status: :ok, **options)
          render json: { data: blueprint.render_as_hash(object, **options) }, status:
        end
      end
    end
  end
end
