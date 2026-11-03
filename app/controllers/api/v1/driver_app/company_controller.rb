# Convoy Driver app › Account › Transport Company, Contact Operations and Company Links: the company picked for the sign-in.
module Api
  module V1
    module DriverApp
      class CompanyController < BaseController
        before_action :require_membership!

        # GET /driver/company
        def show
          company = current_membership.company
          render_data current_membership, DriverCompanyBlueprint,
                      uen: FinanceSetting.find_by(company_id: company.id)&.brand_uen,
                      vehicles_count: Vehicle.kept.where(operator_id: nil).count
        end
      end
    end
  end
end
