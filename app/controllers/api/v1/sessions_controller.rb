module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_user!, only: [ :create, :demo ]

      # GET /api/v1/session
      def show
        Rails.logger.info "[SESSION] current_user=#{current_user&.id} session_keys=#{session.keys}"
        cid = current_user.super_admin? ? session[:convoy_company_id] : current_user.company_id
        render json: {
          user: {
            id:        current_user.id,
            name:      current_user.name,
            email:     current_user.email,
            role:      current_user.role,
            companyId: cid,
            perms:     current_user.effective_permissions
          },
          companyId: cid,
          schoolId:  current_school_id,
          date:      current_date,
          company:   current_company ? CompanyBlueprint.render_as_hash(current_company) : nil
        }
      end

      # POST /api/v1/login
      def create
        user = User.find_by(email: params[:email]&.downcase&.strip)
        if user&.valid_password?(params[:password])
          sign_in(user)
          render json: { ok: true }
        else
          render json: { error: "Email or password is incorrect" }, status: :unauthorized
        end
      end

      # POST /api/v1/login-as (demo mode only)
      def demo
        unless ENV["DEMO_LOGIN"] == "true" || Rails.env.development?
          return render json: { error: "Quick sign-in is off. Set DEMO_LOGIN=true for prototypes" }, status: :forbidden
        end
        user = params[:kind] == "super" ? User.find_by(role: "super") : User.find_by(role: "admin")
        return render json: { error: "No such account" }, status: :not_found unless user
        sign_in(user)
        render json: { ok: true }
      end

      # DELETE /api/v1/logout
      def destroy
        Rails.logger.info "[LOGOUT] current_user=#{current_user&.id} session_keys=#{session.keys}"
        sign_out(current_user)
        reset_session
        Rails.logger.info "[LOGOUT] after sign_out+reset session_keys=#{session.keys}"
        render json: { ok: true }
      end

      # POST /api/v1/context
      def update_context
        body = params.permit(:companyId, :schoolId, :date)

        if body[:companyId].present?
          if !current_user.super_admin? && body[:companyId] != current_user.company_id.to_s
            return render json: { error: "Not allowed" }, status: :forbidden
          end
          session[:convoy_company_id] = body[:companyId].to_i
          session[:convoy_school_id] = nil
        end

        if body[:schoolId].present?
          cid = current_user.super_admin? ? session[:convoy_company_id] : current_user.company_id
          unless School.exists?(id: body[:schoolId], company_id: cid)
            return render json: { error: "School not found" }, status: :not_found
          end
          session[:convoy_school_id] = body[:schoolId]
        end

        session[:convoy_date] = body[:date].to_s[0, 10] if body[:date].present?
        render json: { ok: true }
      end
    end
  end
end
