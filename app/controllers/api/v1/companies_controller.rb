# Transport companies: Convoy Admin opens and manages them; company users read their own and (with the Users permission)
# change Company Settings. Picking the country once stamps who and when; after that it is locked (country_requests).
module Api
  module V1
    class CompaniesController < BaseController
      skip_before_action :assign_tenant

      # GET /api/v1/companies — Convoy Admin: every company; others: their own.
      def index
        authorize Company
        companies = policy_scope(Company).includes(:country_set_by, pending_country_request: %i[company requested_by decided_by])
                                         .ransack(ransack_params).result.order(:name)
        render_page companies, CompanyBlueprint, view: view_name, actor: current_user
      end

      def show
        render_company authorize(Company.find(params[:id]))
      end

      def create
        company = authorize(Company.new(permitted_attributes(Company)))
        company.save!
        render_company company, status: :created
      end

      def update
        company = authorize(Company.find(params[:id]))
        company.assign_attributes(permitted_attributes(company))
        company.assign_attributes(country_set_at: Time.current, country_set_by: current_user) if company.country_changed? && !current_user.convoy_admin?
        company.save!
        render_company company
      end

      private

      def view_name
        current_user.convoy_admin? ? :platform : :settings
      end

      def render_company(company, status: :ok)
        render_data company, CompanyBlueprint, view: view_name, actor: current_user, status:
      end
    end
  end
end
