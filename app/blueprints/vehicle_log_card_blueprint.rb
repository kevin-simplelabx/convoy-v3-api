class VehicleLogCardBlueprint < ApplicationBlueprint
  fields :vehicle_id, :current, :plate_on_card, :plate_conflict, :created_at
  field(:file) { |c| c.file_info(:file) }
  field(:uploaded_by) { |c| c.uploaded_by&.name }
end
