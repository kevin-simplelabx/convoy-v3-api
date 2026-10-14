module Api
  module V1
    class CompaniesController < BaseController
      # GET /api/v1/companies
      def index
        companies = current_user.super_admin? ? Company.all : Company.where(id: current_user.company_id)
        render json: CompanyBlueprint.render(companies, view: :with_stats)
      end

      # POST /api/v1/companies (Convoy Admin only)
      def create
        return render_error("Only Convoy admins can add transport companies", :forbidden) unless current_user.super_admin?

        p = params.permit(:name, :email, :password, :adminName)
        return render_error("Fill in every field") if p.values_at(:name, :email, :password, :adminName).any?(&:blank?)
        return render_error("Password needs at least 8 characters") if p[:password].length < 8
        return render_error("That email already has an account") if User.exists?(email: p[:email].downcase.strip)

        company = Company.create!(name: p[:name].strip)
        User.create!(
          name: p[:adminName].strip,
          email: p[:email].strip,
          password: p[:password],
          role: "admin",
          permissions: User::ALL_PERMISSIONS,
          company: company
        )
        render json: CompanyBlueprint.render(company), status: :created
      end

      # PUT /api/v1/company/logo
      def update_logo
        require_company!
        return unless performed?
        require_permission!("users")
        return unless performed?

        logo = params[:logo]
        if logo.present? && !/\Adata:image\/(png|jpeg|webp);base64,/.match?(logo)
          return render_error("Logo must be a PNG, JPG or WebP under 300 KB")
        end
        return render_error("Logo must be a PNG, JPG or WebP under 300 KB") if logo.present? && logo.length > 400_000

        current_company.update!(logo: logo.presence)
        render json: { logo: current_company.logo }
      end
    end
  end
end
