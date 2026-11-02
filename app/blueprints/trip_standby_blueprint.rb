class TripStandbyBlueprint < ApplicationBlueprint
  fields :location, :minutes, :lat, :lng, :address, :note, :street_view_url
  field(:report_time) { |s| Clock.hm(s.report_time) }
  field(:photos) { |s| s.photos.map { |p| { id: p.id, position: p.position }.merge(p.decorate.file_info(:photo, versions: [ :thumb ])) } }
end
