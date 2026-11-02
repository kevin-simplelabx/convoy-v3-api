# Fuel Companies window (Fuel & Energy): the list (Singapore defaults on first use) with how many entries use each,
# saved at once.
module Api
  module V1
    class FuelCompaniesController < BaseController
      def index
        authorize FuelCompany
        FuelCompany.ensure_defaults! if current_user.can?(:vehicles) && !current_user.convoy_admin?
        render_list policy_scope(FuelCompany), FuelCompanyBlueprint, usage:
      end

      # PUT /fuel_companies/bulk { companies: [{ id?, name, kind }] } — a company left out is deleted (not when in use).
      def bulk
        authorize FuelCompany, :update?
        rows = params.permit(companies: %i[id name kind]).fetch(:companies, [])
        render_list FuelCompanies::Save.call(rows:), FuelCompanyBlueprint, usage:
      end

      private

      def usage = FuelEntry.where.not(fuel_company_id: nil).group(:fuel_company_id).count
    end
  end
end
