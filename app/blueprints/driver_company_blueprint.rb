# Account › Transport Company (and Contact Operations, Company Links) for the company picked in the Driver app.
# Render the membership; pass vehicles_count:, uen:.
class DriverCompanyBlueprint < Blueprinter::Base
  field(:membership) { |m| DriverMembershipBlueprint.render_as_hash(m) }
  field(:uen) { |_m, o| o[:uen] }
  field(:vehicles_count) { |_m, o| o[:vehicles_count] }
  field(:role) { |m| m.is_a?(OperatorDriver) ? "Driver, #{m.operator.name}" : "Driver" }
  field(:operations) do |m|
    c = m.company
    phone = ->(v) { v && Phonelib.parse(v).then { |p| p.valid? ? p.international : v } }
    { phone: phone.(c.ops_phone), hours: c.ops_hours, whatsapp: phone.(c.ops_whatsapp), email: c.ops_email, depot_address: c.depot_address }
  end
  field(:links) { |m| m.company.links.map { |l| { id: l.id, title: l.title, url: l.url, note: l.note } } }
end
