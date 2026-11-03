# A handover (Switch Vehicle) in the Driver app and My Vehicle Today: when, which bus, the six photos and the declaration.
class DriverHandoverBlueprint < Blueprinter::Base
  identifier :id
  fields :at, :declared_at, :note

  field(:vehicle) { |h| { id: h.vehicle.id, plate: h.vehicle.plate } }
  field(:photos) do |h|
    h.photos.map(&:decorate).map do |p|
      { side: p.side, label: VehicleHandover::SIDE_LABELS[p.side], photo: p.photo_info, marked_photo: p.marked_photo_info, marks: p.marks }
    end
  end
end
