# Insurance of a vehicle (Edit Vehicle): current policy and Past Policies, edit, Renew Policy, delete a past policy.
module Api
  module V1
    class VehicleInsurancePoliciesController < BaseController
      before_action :set_vehicle

      def index
        authorize VehicleInsurancePolicy
        policies = @vehicle.insurance_policies.includes(:documents).order(current: :desc, ends_on: :desc)
        render_list policies, VehicleInsurancePolicyBlueprint
      end

      def update
        policy = authorize @vehicle.insurance_policies.find(params[:id])
        policy.update!(policy_params)
        render_data policy, VehicleInsurancePolicyBlueprint
      end

      # POST /vehicles/:vehicle_id/insurance_policies { ... } — start the current policy by hand.
      def create
        policy = authorize @vehicle.insurance_policies.new(policy_params.merge(current: true))
        policy.save!
        render_data policy, VehicleInsurancePolicyBlueprint, status: :created
      end

      def renew
        authorize VehicleInsurancePolicy
        render_data VehicleDocuments::RenewInsurance.call(vehicle: @vehicle), VehicleInsurancePolicyBlueprint, status: :created
      end

      def destroy
        authorize(@vehicle.insurance_policies.find(params[:id])).destroy!
        head :no_content
      end

      private

      def set_vehicle
        @vehicle = Vehicle.kept.find(params[:vehicle_id])
      end

      def policy_params
        params.expect(vehicle_insurance_policy: %i[insurer policy_number cover_type starts_on ends_on excess excess_third_party
                                                   hire_purchase_company agent holder premium gst total debit_note_number
                                                   debit_note_date paid_on])
      end
    end
  end
end
