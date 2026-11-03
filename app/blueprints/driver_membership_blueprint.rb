# One company record of a driver in the Convoy Driver app: an invitation (pending), the company they work for (active)
# or one they left (past, Employment History). A managed driver sees their operator's name, "Managed by" the company.
class DriverMembershipBlueprint < Blueprinter::Base
  field(:key) { |m| DriverMembership.key(m) }
  field(:kind) { |m| DriverMembership.kind(m) }
  field :status
  field(:company) do |m|
    c = m.company.decorate
    { id: c.id, name: c.name, display_name: c.display_name, theme_color: c.theme_color, logo: c.logo_info }
  end
  field(:employer_name) { |m| DriverMembership.employer_name(m) }
  field(:managed_by) { |m| m.company.name if m.is_a?(OperatorDriver) }
  field(:name_on_record) { |m| m.name }
  fields :invited_at, :joined_at, :left_at
  # Employment History: completed runs at that company (pass metrics: DriverApp::Metrics.call).
  field(:trips_completed, if: ->(_name, _m, o) { o.key?(:metrics) }) { |m, o| o[:metrics].dig(DriverMembership.key(m), :trips) || 0 }
end
