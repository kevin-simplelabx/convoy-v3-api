# A PUDO point of a stop.
class StopPointBlueprint < ApplicationBlueprint
  fields :suffix, :description, :usage, :sizes, :primary, :subzone_code, :street_view_url, :photo_annotations, :photo_credit
  field(:pudo_code) { |p| p.pudo_code }
  field(:lat) { |p| p.lat.to_f }
  field(:lng) { |p| p.lng.to_f }
  field(:photo) { |p| p.decorate.photo_info }
  field(:photo_original) { |p| p.decorate.photo_original_info }
end
