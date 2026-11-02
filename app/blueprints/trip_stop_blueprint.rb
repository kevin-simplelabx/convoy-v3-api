class TripStopBlueprint < ApplicationBlueprint
  fields :direction, :position, :name, :use, :address, :lat, :lng, :driver_note, :street_view_url, :client_site_id
  field(:scheduled_time) { |s| s.scheduled_time_hm }
  field(:students) do |s|
    s.students.map { |st| st.slice(:id, :key, :position, :name, :class_name, :parent_name, :phone, :phone2, :note) }
  end
  field(:photos) { |s| s.photos.map { |p| { id: p.id, position: p.position }.merge(p.decorate.file_info(:photo, versions: [ :thumb ])) } }
end
