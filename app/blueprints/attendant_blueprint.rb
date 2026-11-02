class AttendantBlueprint < ApplicationBlueprint
  fields :name, :phone, :notes
  field(:photo) { |a| a.photo_info }
end
