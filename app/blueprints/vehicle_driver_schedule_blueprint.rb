class VehicleDriverScheduleBlueprint < ApplicationBlueprint
  fields :vehicle_id, :starts_on, :created_at
  field(:start_time) { |s| s.start_time_hm }
  field(:ends_on) { |s, options| options[:ends]&.dig(s.id, :on) }
  field(:ends_at) { |s, options| options[:ends]&.dig(s.id, :at) }
  field(:driver) { |s| s.driver && { id: s.driver.id, name: s.driver.name, phone: s.driver.phone } }
end
