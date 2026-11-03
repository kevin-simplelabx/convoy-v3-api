# Base for the Convoy Driver app API (/api/v1/driver, Bearer token of scope driver_account). Convoy OS and Client Portal
# tokens are refused here, and a Driver app token is refused by them. Work runs in the company (tenant) and timezone of
# the membership picked for the sign-in; changes are audited as the driver's account. Everything a driver reaches is
# their own (account, memberships, runs), so access is by scoping, not Pundit.
module Api
  module V1
    module DriverApp
      class BaseController < ApplicationController
        include ErrorHandling

        before_action :authenticate_driver!
        around_action :in_membership_company

        private

        def authenticate_driver!
          raise ErrorHandling::Unauthenticated unless current_driver_jwt
        end

        def current_driver_jwt
          return @current_driver_jwt if defined?(@current_driver_jwt)

          @current_driver_jwt = ::DriverApp::FindToken.call(token: request.authorization.to_s[/\ABearer\s+(\S+)\z/i, 1])
        end

        def current_account = current_driver_jwt&.driver_account

        # The company record picked for this sign-in (own driver or operator driver), or nil.
        def current_membership
          return @current_membership if defined?(@current_membership)

          @current_membership = current_driver_jwt&.membership
        end

        # For endpoints about work at a company (runs, vehicle): 422 "Pick a company first" without one.
        def require_membership!
          raise ActsAsTenant::Errors::NoTenantSet unless current_membership
        end

        def in_membership_company(&)
          company = current_membership&.company
          Audited.audit_class.as_user(current_account) do
            ActsAsTenant.with_tenant(company) { Time.use_zone(company&.timezone || Time.zone, &) }
          end
        end

        def render_data(object, blueprint, status: :ok, **options)
          render json: { data: blueprint.render_as_hash(object, **options) }, status:
        end
      end
    end
  end
end
