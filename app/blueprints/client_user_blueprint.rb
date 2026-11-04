class ClientUserBlueprint < ApplicationBlueprint
  fields :client_id, :name, :title, :email, :role, :role_label, :created_at

  field(:wide) { |u| u.wide? }
  field(:sites) { |u| u.wide? ? [] : u.sites.sort_by(&:name).map { |s| { id: s.id, name: s.name } } }
  field(:team) { |u| u.team && { id: u.team.id, name: u.team.name } }
  field(:manager) { |u| u.manager && { id: u.manager.id, name: u.manager.name } }
  # Added by a Convoy OS user (created_by) or, in the Client Portal, by a client user (created_by_client_user).
  field(:created_by) do |u|
    if u.created_by then { id: u.created_by.id, name: u.created_by.shown_name, in_portal: false }
    elsif u.created_by_client_user then { id: u.created_by_client_user.id, name: u.created_by_client_user.name, in_portal: true }
    end
  end
  # Client Portal: whether the person has set a password (signed in once) and when they last signed in.
  field(:portal) { |u| { password_set: u.portal_account.password_set?, last_sign_in_at: u.portal_account.last_sign_in_at } }
end
