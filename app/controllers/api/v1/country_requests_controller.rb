# Company Settings > Request a Country Change (company: send, withdraw, history) and the Convoy Admin side (approve / decline).
module Api
  module V1
    class CountryRequestsController < BaseController
      skip_before_action :assign_tenant

      def index
        authorize CompanyCountryRequest
        scope = policy_scope(CompanyCountryRequest).includes(:company, :requested_by, :decided_by).order(created_at: :desc)
        scope = scope.where(status: params[:status]) if params[:status].present?
        scope = scope.where(company_id: params[:company_id]) if params[:company_id].present?
        render_page scope, CompanyCountryRequestBlueprint
      end

      # POST /country_requests { country_request: { to_country, reason } }
      def create
        request = authorize CompanyCountryRequest.new(params.expect(country_request: %i[to_country reason])
                                                        .merge(company: current_user.company, requested_by: current_user))
        request.save!
        render_data request, CompanyCountryRequestBlueprint, status: :created
      end

      def withdraw = decide(:withdraw!)
      def approve = decide(:approve!)
      def decline = decide(:decline!)

      private

      def decide(action)
        request = authorize policy_scope(CompanyCountryRequest).pending.find(params[:id]), :"#{action.to_s.chomp('!')}?"
        request.public_send(action, user: current_user)
        render_data request, CompanyCountryRequestBlueprint
      end
    end
  end
end
