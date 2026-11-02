# Client Portal: Set Password and Sign In, after a correct one-time code (first sign-in or forgotten password).
module Api
  module V1
    module Portal
      class PasswordsController < SessionsController
        # POST /portal/password { set_password_token, password, password_confirmation, device_name }
        def create
          account = ::Portal::PasswordToken.account_for(params.require(:set_password_token))
          raise ApplicationService::Error, "This link has expired. Ask for a new code" unless account

          account.password = params.require(:password)
          account.password_confirmation = params[:password_confirmation]
          account.password_set_at = Time.current
          account.save!
          account.portal_jwts.delete_all
          render_signed_in(account)
        end
      end
    end
  end
end
