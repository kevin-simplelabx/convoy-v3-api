# School Bus › Dashboard of a school: Operations for everyone who can open the school; Finance (a month) for users with
# finance or finview.
module Api
  module V1
    class SchoolDashboardController < BaseController
      # GET /schools/:school_id/dashboard?bin=tier|1|2
      def show
        school = authorize find_school, :show?
        render json: { data: { school: { id: school.id, name: school.name }, finance_allowed: policy(school).money_view?,
                               operations: SchoolDashboard::Ops.new(school, bin: params[:bin]).call } }
      end

      # GET /schools/:school_id/dashboard/finance?month=YYYY-MM
      def finance
        school = authorize find_school, :money_view?
        render json: { data: SchoolDashboard::Money.new(school, month).call }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def month
        params[:month].present? ? Date.strptime(params[:month], "%Y-%m") : Date.current.beginning_of_month
      rescue Date::Error
        raise ApplicationService::Error, "Month must look like 2026-11"
      end
    end
  end
end
