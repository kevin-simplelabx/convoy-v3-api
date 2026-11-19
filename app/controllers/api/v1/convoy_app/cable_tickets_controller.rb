# Convoy App WebSocket: a one-time ticket to open /cable (integration.md § WebSocket).
module Api
  module V1
    module ConvoyApp
      class CableTicketsController < BaseController
        # POST /app/cable_ticket → { ticket, expires_in, url }
        def create
          render json: { data: { ticket: CableTicket.issue!(current_app_jwt), expires_in: CableTicket::TTL.to_i, url: "/cable" } }, status: :created
        end
      end
    end
  end
end
