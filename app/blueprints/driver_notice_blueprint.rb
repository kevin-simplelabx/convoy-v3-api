# A notice's detail page in the Driver app. Render a decorated DriverNotice; pass recipient: (this driver's row).
class DriverNoticeBlueprint < Blueprinter::Base
  identifier :id
  fields :kind, :title, :summary, :body, :image_caption, :from_name, :starts_at, :ends_at

  field(:image) { |n| n.image_info }
  field(:link) { |n| n.link_url.present? ? { url: n.link_url, label: n.link_label.presence || n.link_url } : nil }
  field(:read_at) { |_n, o| o[:recipient]&.read_at }
  field(:acknowledged_at) { |_n, o| o[:recipient]&.acknowledged_at }
  field(:needs_ack) { |n, o| n.kind == "ack" && o[:recipient]&.acknowledged_at.nil? }
end
