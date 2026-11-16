# Convoy App › Quick Invite link, opened by the person invited (they need not be in a Family; they are signed in).
module Api
  module V1
    module ConvoyApp
      class HouseholdLinksController < BaseController
        # GET /app/household/links/:token → { family, invited_by, expires_at }  (404 no such link, 422 link_expired)
        def show
          link = ::ConvoyApp::Households::JoinByLink.new(token: params[:token]).find
          render json: { data: { family: link.household.name, invited_by: link.created_by&.display_name, expires_at: link.expires_at } }
        end

        # POST /app/household/links/:token/join → { status: "requested", family } (Asked to Join; the Admin approves)
        def join
          member = ::ConvoyApp::Households::JoinByLink.call(token: params[:token], account: current_account)
          render json: { data: { status: member.status, family: member.household.name } }, status: :created
        end
      end
    end
  end
end
