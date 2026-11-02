module Api
  module V1
    class CompaniesController < BaseController
      skip_before_action :assign_tenant

      # GET /api/v1/companies — Convoy Admin: every company; others: their own.
      def index
        authorize Company
        companies = policy_scope(Company).ransack(ransack_params).result.order(:name)
        render_page companies, CompanyBlueprint, view: view_name
      end

      def show
        render_data authorize(Company.find(params[:id])), CompanyBlueprint, view: view_name
      end

      def create
        company = authorize(Company.new(permitted_attributes(Company)))
        company.save!
        render_data company, CompanyBlueprint, view: view_name, status: :created
      end

      def update
        company = authorize(Company.find(params[:id]))
        company.update!(permitted_attributes(company))
        render_data company, CompanyBlueprint, view: view_name
      end

      private

      def view_name
        current_user.convoy_admin? ? :platform : :default
      end
    end
  end
end
