# A client user in the Client Portal (Settings › Users), with what the viewer may do to them (options[:viewer]).
class PortalUserBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :email, :role, :role_label

  field(:wide) { |u| u.wide? }
  field(:sites) { |u| u.wide? ? [] : u.sites.sort_by(&:name).map { |s| { id: s.id, name: s.name } } }
  field(:team) { |u| u.team && { id: u.team.id, name: u.team.name } }
  field(:manager) { |u| u.manager && { id: u.manager.id, name: u.manager.name } }
  field(:signed_in) { |u| u.portal_account.password_set? }
  field(:last_sign_in_at) { |u| u.portal_account.last_sign_in_at }
  field(:me) { |u, o| u.id == o[:viewer].id }
  field(:can_edit) { |u, o| o[:viewer].manages?(u, :edit) }
  field(:can_remove) { |u, o| o[:viewer].manages?(u, :remove) }
end
