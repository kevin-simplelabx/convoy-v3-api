# Client Portal sign-in. Email first (lookup): a person who has set a password types it; at first sign-in a one-time
# code is emailed, then they set their password (verify → PasswordsController). Forgot password = a new code.
# One person can be a user of several clients: the session lists them and one is picked (PATCH) for the token.
module Api
  module V1
    module Portal
      class SessionsController < BaseController
        before_action :authenticate_portal!, only: %i[show update destroy]

        NO_ACCOUNT = "No client account for this email. Ask your transport company to add you under Managed Clients".freeze

        # POST /portal/session/lookup { email } → { next: "password" } or { next: "code", purpose: "first" } (code emailed)
        def lookup
          account = find_account!
          return render(json: { data: { email: account.email, next: "password" } }) if account.password_set?

          send_code(account, :first)
        end

        # POST /portal/session/code { email } — Forgot password? Send a code instead.
        def code
          account = find_account!
          send_code(account, account.password_set? ? :reset : :first)
        end

        # POST /portal/session/verify { email, code } → { set_password_token } for POST /portal/password
        def verify
          account = find_account!
          record = account.sign_in_codes.usable.order(created_at: :desc).first
          raise ApplicationService::Error, "That code has expired. Send a new one" unless record
          raise ApplicationService::Error, "That code is not right. Check the email and try again" unless record.check!(params.require(:code))

          render json: { data: { set_password_token: ::Portal::PasswordToken.generate(account), purpose: record.purpose } }
        end

        # POST /portal/session { email, password, device_name }
        def create
          account = PortalAccount.find_by(email: params.require(:email).to_s.strip.downcase)
          unless account&.password_set? && account.valid_password?(params.require(:password)) && account.accounts.any?
            return render_error(:unauthorized, "Email or password is incorrect")
          end

          render_signed_in(account)
        end

        def show = render_session

        # PATCH /portal/session { client_user_id } — pick the client account for this sign-in.
        def update
          pick = current_account.accounts.find { |u| u.id == params.require(:client_user_id).to_i }
          raise ActiveRecord::RecordNotFound unless pick

          current_portal_jwt.update!(client_user: pick)
          render_session
        end

        def destroy
          current_portal_jwt.destroy!
          head :no_content
        end

        private

        def find_account!
          account = PortalAccount.find_by(email: params.require(:email).to_s.strip.downcase)
          raise ApplicationService::Error, NO_ACCOUNT unless account&.accounts&.any?

          account
        end

        def send_code(account, purpose)
          code = ::Portal::SendCode.call(account:, purpose:, ip: request.remote_ip)
          render json: { data: { email: account.email, next: "code", purpose: purpose.to_s, **dev_code(code) } }
        end

        # Until SMTP is set up, dev / staging show the code (PORTAL_SHOW_CODE=1). Never set it in production.
        def dev_code(code) = ENV["PORTAL_SHOW_CODE"] == "1" ? { dev_code: code } : {}

        def render_signed_in(account)
          token, @current_portal_jwt = ::Portal::IssueToken.call(account:, name: params[:device_name])
          render_session(token:)
        end

        def render_session(token: nil)
          jwt = current_portal_jwt
          accounts = jwt.portal_account.accounts
          render json: {
            data: {
              **(token ? { token:, token_type: "Bearer", expires_at: jwt.exp.iso8601 } : {}),
              account: { id: jwt.portal_account.id, email: jwt.portal_account.email, name: jwt.portal_account.name },
              accounts: PortalAccountBlueprint.render_as_hash(accounts),
              current: accounts.find { |u| u.id == jwt.client_user_id }&.then { |u| PortalAccountBlueprint.render_as_hash(u) }
            }
          }
        end
      end
    end
  end
end
