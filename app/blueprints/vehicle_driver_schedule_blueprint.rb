class VehicleDriverScheduleBlueprint < ApplicationBlueprint
  fields :vehicle_id, :starts_on, :created_at
  field(:ends_on) { |s, options| options[:ends]&.dig(s.id) }
  field(:driver) { |s| s.driver && { id: s.driver.id, name: s.driver.name, phone: s.driver.phone } }
end
