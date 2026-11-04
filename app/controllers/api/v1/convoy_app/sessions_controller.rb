# Convoy App sign-in (and sign-up: the same step): mobile or email → one-time code (always 123456 for now) → token. The
# first code for a new mobile / email creates the account; profile_complete false → Create Your Account (PATCH /app/profile).
# Several phones may be signed in at once.
module Api
  module V1
    module ConvoyApp
      class SessionsController < BaseController
        skip_before_action :authenticate_app!, only: %i[code create]
        skip_before_action :require_profile!

        # POST /app/session/code { mobile } or { email } → { kind, value, display }
        def code
          render json: { data: ::ConvoyApp::SendCode.call(mobile: params[:mobile], email: params[:email], ip: request.remote_ip) }
        end

        # POST /app/session { mobile | email, code, device_name }
        def create
          token, @current_app_jwt = ::ConvoyApp::SignIn.call(mobile: params[:mobile], email: params[:email], code: params.require(:code),
                                                             device_name: params[:device_name])
          render_session(token:)
        end

        # GET /app/session
        def show = render_session

        # DELETE /app/session — Sign Out (this phone; its push token goes too).
        def destroy
          current_app_jwt.destroy!
          head :no_content
        end

        private

        def render_session(token: nil)
          jwt = current_app_jwt
          render json: {
            data: {
              **(token ? { token:, token_type: "Bearer", expires_at: jwt.exp.iso8601 } : {}),
              account: AppAccountBlueprint.render_as_hash(jwt.app_account.decorate)
            }
          }
        end
      end
    end
  end
end
