class VehicleInsuranceDocumentBlueprint < ApplicationBlueprint
  fields :kind, :kind_name, :plate_on_document, :plate_differs, :created_at
  field(:file) { |d| d.file_info(:file) }
end
