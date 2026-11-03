# A line on the Driver app's bell. Pass member: (to read the notice's acknowledgement).
class DriverNotificationBlueprint < Blueprinter::Base
  identifier :id
  fields :kind, :title, :body

  field(:at) { |n| n.created_at }
  field(:read) { |n| n.read_at.present? }
  field(:run) { |n| n.occurrence_id && { id: n.occurrence_id, date: n.occurrence_date } }
  field(:vehicle) { |n| n.vehicle && { id: n.vehicle.id, plate: n.vehicle.plate } }
  field(:notice) do |n, o|
    next unless n.notice

    r = o[:recipients]&.dig(n.driver_notice_id)
    { id: n.notice.id, kind: n.notice.kind, acknowledged_at: r&.acknowledged_at }
  end
end
