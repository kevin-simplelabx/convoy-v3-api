# Base of the channels. Every channel closes the socket when its sign-in has ended (signed out or expired).
module ApplicationCable
  class Channel < ActionCable::Channel::Base
    SIGN_IN_CHECK = 5.minutes

    periodically :check_sign_in, every: SIGN_IN_CHECK

    private

    def driver_account_id = connection.driver_jwt&.driver_account_id
    def app_account = connection.app_jwt&.app_account

    # Still signed in (the sign-in row is there and not expired)?
    def signed_in?
      jwt = connection.driver_jwt || connection.app_jwt
      jwt.present? && jwt.class.exists?(id: jwt.id, exp: Time.current..)
    end

    def check_sign_in
      connection.close(reason: ActionCable::INTERNAL[:disconnect_reasons][:unauthorized], reconnect: false) unless signed_in?
    end
  end
end
