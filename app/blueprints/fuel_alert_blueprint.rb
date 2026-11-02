class FuelAlertBlueprint < ApplicationBlueprint
  fields :vehicle_id, :fuel_entry_id, :kind, :tone, :metric, :message, :date, :status, :checked_at
  field(:plate) { |a| a.vehicle.plate }
  field(:checked_by) { |a| a.checked_by&.name }
  # The fill it is about: kind, quantity, where (for the row's second line).
  field(:entry) do |a|
    e = a.fuel_entry
    e && { kind_name: e.kind_name, quantity: e.quantity, unit: e.unit, time: e.time_hm, driver_name: e.driver&.name,
           place: [ e.fuel_company&.name, e.station ].compact_blank.join(" ").presence }
  end
end
