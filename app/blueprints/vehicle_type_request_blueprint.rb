class VehicleTypeRequestBlueprint < ApplicationBlueprint
  fields :name, :seats, :reason, :status, :status_label, :vehicle_type_id, :decided_at, :created_at
  field(:company) { |r| { id: r.company_id, name: r.company.name } }
  field(:requested_by) { |r| r.requested_by&.name }
end
