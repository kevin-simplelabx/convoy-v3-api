class ExternalVehicleSubmissionBlueprint < ApplicationBlueprint
  fields :plate, :seats, :driver_name, :driver_phone, :company_name, :company_phone, :paynow, :status, :vehicle_id,
         :decided_at, :created_at
end
