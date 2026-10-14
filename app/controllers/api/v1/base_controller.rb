module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      # Current company resolved from session or user record
      def current_company
        return @current_company if defined?(@current_company)
        cid = current_user.super_admin? ? session[:convoy_company_id] : current_user.company_id
        @current_company = cid ? Company.find_by(id: cid) : nil
      end

      def current_school_id
        session[:convoy_school_id]
      end

      def current_date
        session[:convoy_date] || Date.today.iso8601
      end

      def require_company!
        render json: { error: "Pick a transport company first" }, status: :bad_request unless current_company
      end

      # Blocks writes for super_admin; regular users need the named permission.
      def require_permission!(perm)
        return render json: { error: "Convoy Admin has view-only access to company data" }, status: :forbidden if current_user.super_admin?
        render json: { error: "You do not have permission for this" }, status: :forbidden unless current_user.has_permission?(perm)
      end

      # Allows super_admin to read (view-only design); regular users need the permission.
      def require_read_permission!(perm)
        return if current_user.super_admin?
        render json: { error: "You do not have permission for this" }, status: :forbidden unless current_user.has_permission?(perm)
      end

      private

      def render_error(message, status = :bad_request)
        render json: { error: message }, status: status
      end
    end
  end
end
