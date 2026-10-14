class SchoolBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :short, :address, :postal, :lat, :lng, :created_at

  field :company_id
  field :labels do |school|
    school.effective_labels
  end
end
