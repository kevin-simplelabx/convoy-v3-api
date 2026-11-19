# The WebSocket of one Driver app or Convoy App sign-in, opened with a one-time ticket (/cable?ticket=…, CableTicket).
# Anything else is refused. Signing out (or a new sign-in on another phone for a driver) closes it: see Realtime.disconnect;
# channels also re-check the sign-in every few minutes (an expired token; ApplicationCable::Channel).
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :driver_jwt, :app_jwt

    def connect
      jwt = CableTicket.redeem(request.params[:ticket]) || reject_unauthorized_connection
      if jwt.is_a?(DriverJwt) then self.driver_jwt = jwt
      else self.app_jwt = jwt
      end
    end
  end
end
