class AttendantBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :contact, :notes, :created_at, :updated_at
end
