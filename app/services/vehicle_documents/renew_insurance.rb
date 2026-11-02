# Renew Policy: the current policy (with its premium and files) moves to Past Policies; a new empty one starts.
module VehicleDocuments
  class RenewInsurance < ApplicationService
    def initialize(vehicle:)
      @vehicle = vehicle
    end

    def call
      VehicleInsurancePolicy.transaction do
        current = @vehicle.current_insurance_policy
        raise Error, "There is no policy to renew" if current.nil?

        current.update!(current: false, renewed_at: Time.current)
        @vehicle.insurance_policies.create!(current: true, insurer: current.insurer, agent: current.agent,
                                            hire_purchase_company: current.hire_purchase_company, cover_type: current.cover_type,
                                            starts_on: current.ends_on&.next_day)
      end
    end
  end
end
