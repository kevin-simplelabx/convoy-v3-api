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
        render_page companies, CompanyBlueprint, view: view_name, actor: current_user, **platform_options(companies)
      end

      def show
        render_company authorize(Company.find(params[:id]))
      end

      # POST /companies { company: {...}, admin: { name, email, password } } — Convoy Admin.
      def create
        authorize Company
        company = Companies::Create.call(params: permitted_attributes(Company), admin: params.expect(admin: %i[name email password]))
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
        render_data company, CompanyBlueprint, view: view_name, actor: current_user, status:, **platform_options([ company ])
      end

      # Admin email, schools and users of each company (Convoy Admin list), and the company opened for this sign-in.
      def platform_options(companies)
        return {} unless current_user.convoy_admin?

        ids = companies.map(&:id)
        owners = User.kept.where(company_id: ids, owner: true).order(:id).group_by(&:company_id).transform_values { |u| { name: u.first.name, email: u.first.email } }
        users = User.kept.where(company_id: ids).group(:company_id).count
        schools = ActsAsTenant.without_tenant { School.where(company_id: ids).group(:company_id).count }
        { stats: ids.index_with { |id| { admin: owners[id], users: users[id], schools: schools[id] } }, current_id: current_jwt.company_id }
      end
    end
  end
end
