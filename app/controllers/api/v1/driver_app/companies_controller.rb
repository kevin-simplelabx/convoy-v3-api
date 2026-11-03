# Convoy Driver app › Account › Transport Company and invitations: the companies a driver works for (active), is invited
# by (pending) or has left (past, Employment History), and the driver's answers. A company is named by membership key.
module Api
  module V1
    module DriverApp
      class CompaniesController < BaseController
        # GET /driver/companies
        def index
          members = current_account.memberships
          render_data members, DriverMembershipBlueprint, metrics: ::DriverApp::Metrics.call(members: members.reject(&:pending?))
        end

        # POST /driver/companies/:key/accept | decline | disconnect
        def accept = respond_with_action(:accept)
        def decline = respond_with_action(:decline)
        def disconnect = respond_with_action(:disconnect)

        private

        def respond_with_action(action)
          member = current_account.membership(params[:key])
          raise ActiveRecord::RecordNotFound unless member

          render_data ::DriverApp::Respond.call(jwt: current_driver_jwt, member:, action:), DriverMembershipBlueprint
        end
      end
    end
  end
end
