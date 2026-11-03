class DriverBlueprint < InvitedDriverBlueprint
  # Bus the driver drives by default today: { id, plate, since } (since = start of that default driver entry).
  field(:vehicle) do |d, options|
    s = options[:today]&.dig(d.id)
    s && { id: s.vehicle.id, plate: s.vehicle.plate, since: s.starts_on }
  end
  # Changes still to come: [{ vehicle_id, plate, starts_on }] ("Starts on PD1A from 5 Nov").
  field(:upcoming) do |d, options|
    Array(options[:upcoming]&.dig(d.id)).map { |s| { vehicle_id: s.vehicle_id, plate: s.vehicle.plate, starts_on: s.starts_on, start_time: s.start_time_hm } }
  end
end
