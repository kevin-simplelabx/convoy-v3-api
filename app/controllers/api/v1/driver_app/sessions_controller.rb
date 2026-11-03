# Convoy Driver app sign-in. Mobile number → one-time code (SMS; always 123456 for now) → token; the first correct code
# creates the account. Email and password also sign in once the driver has set them (Account). One phone at a time: a new
# sign-in ends the others. The session lists the driver's companies; one is picked (PATCH) to work in.
module Api
  module V1
    module DriverApp
      class SessionsController < BaseController
        skip_before_action :authenticate_driver!, only: %i[code create email]

        # POST /driver/session/code { phone } → { phone, phone_display, new_account }
        def code
          render json: { data: ::DriverApp::SendCode.call(phone: params.require(:phone), ip: request.remote_ip) }
        end

        # POST /driver/session { phone, code, device_name }
        def create
          token, @current_driver_jwt = ::DriverApp::SignIn.call(phone: params.require(:phone), code: params.require(:code),
                                                                device_name: params[:device_name])
          render_session(token:)
        end

        # POST /driver/session/email { email, password, device_name }
        def email
          account = DriverAccount.find_by(email: DriverAccount.normalize_value_for(:email, params.require(:email)))
          unless account&.password_set? && account.valid_password?(params.require(:password))
            return render_error(:unauthorized, "Email or password is incorrect")
          end

          token, @current_driver_jwt = ::DriverApp::IssueToken.call(account:, name: params[:device_name])
          render_session(token:)
        end

        def show = render_session

        # PATCH /driver/session { membership } — Switch Company: the key of an active membership ("driver-4").
        def update
          member = current_account.membership(params.require(:membership))
          raise ActiveRecord::RecordNotFound unless member

          ::DriverApp::PickMembership.call(jwt: current_driver_jwt, member:)
          render_session
        end

        # DELETE /driver/session — Sign Out (this phone).
        def destroy
          ::DriverApp::SignOut.call(jwt: current_driver_jwt)
          head :no_content
        end

        private

        def render_session(token: nil)
          jwt = current_driver_jwt
          memberships = jwt.driver_account.memberships
          render json: {
            data: {
              **(token ? { token:, token_type: "Bearer", expires_at: jwt.exp.iso8601 } : {}),
              account: DriverAccountBlueprint.render_as_hash(jwt.driver_account.decorate),
              memberships: DriverMembershipBlueprint.render_as_hash(memberships),
              current: memberships.find { |m| DriverMembership.key(m) == jwt.membership_key }&.then { DriverMembershipBlueprint.render_as_hash(it) }
            }
          }
        end
      end
    end
  end
end
