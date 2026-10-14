class DatasetBlueprint < Blueprinter::Base
  identifier :id

  fields :school_id, :effective_from, :file_name, :uploaded_by, :created_at

  field :count do |ds|
    ds.rows.length
  end

  view :summary do
    fields :effective_from, :file_name
  end
end
