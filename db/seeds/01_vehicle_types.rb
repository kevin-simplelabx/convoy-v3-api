# Platform vehicle types (no company).
YAML.load_file(Rails.root.join("config/presets/vehicle_types.yml")).each_with_index do |t, i|
  VehicleType.find_or_initialize_by(key: t["key"]).update!(name: t["name"], seats: t["seats"], tyre_layout: t["tyres"], position: i)
end
