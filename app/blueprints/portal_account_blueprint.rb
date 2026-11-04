# A client account of a Client Portal person (one client user), for the account picker and the Portal shell.
class PortalAccountBlueprint < Blueprinter::Base
  field(:client_user_id) { |u| u.id }
  fields :name, :title, :role, :role_label

  field(:wide) { |u| u.wide? }
  field(:client) { |u| { id: u.client.id, name: u.client.name, kind: u.client.kind, brand: u.client.decorate.brand_info } }
  field(:company) do |u|
    c = u.client.company.decorate
    { id: c.id, name: c.name, display_name: c.display_name, theme_color: c.theme_color, logo: c.logo_info }
  end
end
