class VehicleInsurancePolicyBlueprint < ApplicationBlueprint
  fields :vehicle_id, :current, :insurer, :policy_number, :cover_type, :starts_on, :ends_on, :excess, :excess_third_party,
         :hire_purchase_company, :agent, :holder, :premium, :gst, :total, :debit_note_number, :debit_note_date, :paid_on,
         :renewed_at, :expiry_status, :cover_months
  association :documents, blueprint: VehicleInsuranceDocumentBlueprint
end
