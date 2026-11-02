class OperatorDriverBlueprint < InvitedDriverBlueprint
  fields :operator_id, :vehicle_id, :notes
  field(:operator_name) { |d| d.operator&.name }
  field(:vehicle_plate) { |d| d.vehicle&.plate }
end
