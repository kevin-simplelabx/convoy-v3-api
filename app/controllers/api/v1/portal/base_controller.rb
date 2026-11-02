# Base for the Client Portal API (people at Managed Clients, Bearer token of scope portal_account). Not the Convoy OS
# token: a Convoy OS token is refused here and a Portal token is refused by the Convoy OS API. Work for a client runs
# in that client's company (tenant) once an account is picked.
module Api
  module V1
    module Portal
      class BaseController < ApplicationController
        include ErrorHandling

        private

        def authenticate_portal!
          raise ErrorHandling::Unauthenticated unless current_portal_jwt
        end

        def current_portal_jwt
          return @current_portal_jwt if defined?(@current_portal_jwt)

          @current_portal_jwt = ::Portal::FindToken.call(token: request.authorization.to_s[/\ABearer\s+(\S+)\z/i, 1])
        end

        def current_account = current_portal_jwt&.portal_account
      end
    end
  end
end
