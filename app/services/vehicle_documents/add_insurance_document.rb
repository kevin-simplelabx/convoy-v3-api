# Add an insurance file to the vehicle's current policy (created when there is none): tagged with its kind,
# empty policy fields (and an empty chassis on the vehicle) filled from what Claude read, a different plate warned.
module VehicleDocuments
  class AddInsuranceDocument < ApplicationService
    include SourceFile

    Result = Data.define(:document, :filled)

    def initialize(vehicle:, file: nil, document_read: nil, kind: nil)
      @vehicle = vehicle
      @file = file
      @read = document_read
      @kind = kind
    end

    def call
      file, values = source_file(@file, @read, "insurance")
      values ||= {}

      VehicleInsurancePolicy.transaction do
        policy = @vehicle.current_insurance_policy || @vehicle.insurance_policies.create!(current: true)
        filled = fill_empty(policy, values, Ai::Readers::Insurance::POLICY_FIELDS)
        policy.save!
        filled += fill_empty(@vehicle, values, [ :chassis_number ])
        @vehicle.save! if @vehicle.changed?

        plate = values[:plate]
        document = policy.documents.create!(
          file:, kind: @kind.presence || values[:kind] || "other", plate_on_document: plate,
          plate_differs: plate.present? && @vehicle.plate.present? && plate != @vehicle.plate
        )
        Result.new(document, filled)
      end
    end
  end
end
