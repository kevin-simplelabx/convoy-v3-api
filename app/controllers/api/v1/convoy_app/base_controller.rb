# Base for the Convoy App API (/api/v1/app, Bearer token of scope app_account). Convoy OS, Client Portal and Driver app
# tokens are refused here, and an app token is refused by them. The account is platform-wide; work on a company's data
# runs inside that company (tenant) for each link. Changes are audited as the account. Everything a person reaches is their
# own (account, Family, links), so access is by scoping, not Pundit. Until Create Your Account is done (name and terms)
# only the session, profile, identities and device calls work.
module Api
  module V1
    module ConvoyApp
      class BaseController < ApplicationController
        include ErrorHandling

        before_action :authenticate_app!
        before_action :require_profile!
        around_action :as_account

        private

        def authenticate_app!
          raise ErrorHandling::Unauthenticated unless current_app_jwt
        end

        def current_app_jwt
          return @current_app_jwt if defined?(@current_app_jwt)

          @current_app_jwt = ::ConvoyApp::FindToken.call(token: request.authorization.to_s[/\ABearer\s+(\S+)\z/i, 1])
        end

        def current_account = current_app_jwt&.app_account

        def require_profile!
          return if current_account.profile_complete?

          render_error(:forbidden, "Create your account first", code: "profile_required")
        end

        def as_account(&)
          Audited.audit_class.as_user(current_account, &)
        end

        def render_data(object, blueprint, status: :ok, **options)
          render json: { data: blueprint.render_as_hash(object, **options) }, status:
        end
      end
    end
  end
end
