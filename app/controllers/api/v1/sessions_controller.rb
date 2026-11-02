# Sign in (Bearer token), sign out, who am I, and (Convoy Admin) which company to look at.
module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate!, only: :create
      skip_after_action :verify_authorized

      # GET /api/v1/session
      def show
        render_session
      end

      # POST /api/v1/session { email, password, device_name } → the Bearer token (JWT, 30 days) with the user and company.
      def create
        user = User.find_for_authentication(email: params.require(:email))
        unless user&.valid_password?(params.require(:password)) && user.active_for_authentication?
          return render_error(:unauthorized, "Email or password is incorrect")
        end

        token, @current_jwt = Auth::IssueToken.call(user:, name: params[:device_name])
        user.update_column(:last_seen_at, Time.current)
        reset_company
        render_session(token:)
      end

      # PATCH /api/v1/session { company_id } — Convoy Admin picks the company to view (for this sign-in).
      def update
        return render_error(:forbidden, "Only Convoy Admin can switch company") unless current_user.convoy_admin?

        current_jwt.update!(company: Company.find(params.require(:company_id)))
        reset_company
        render_session
      end

      # DELETE /api/v1/session — signs this token out (other devices stay signed in).
      def destroy
        current_jwt.destroy!
        head :no_content
      end

      private

      def reset_company
        remove_instance_variable(:@current_company) if defined?(@current_company)
      end

      def render_session(token: nil)
        render json: {
          data: {
            **(token ? { token:, token_type: "Bearer", expires_at: current_jwt.exp.iso8601 } : {}),
            user: UserBlueprint.render_as_hash(current_user.decorate),
            company: current_company && CompanyBlueprint.render_as_hash(current_company.decorate)
          }
        }
      end
    end
  end
end
