class ClientUserBlueprint < ApplicationBlueprint
  fields :client_id, :name, :title, :email, :role, :role_label, :created_at

  field(:wide) { |u| u.wide? }
  field(:sites) { |u| u.wide? ? [] : u.sites.sort_by(&:name).map { |s| { id: s.id, name: s.name } } }
  field(:created_by) { |u| u.created_by && { id: u.created_by.id, name: u.created_by.shown_name } }
  # Client Portal: whether the person has set a password (signed in once) and when they last signed in.
  field(:portal) { |u| { password_set: u.portal_account.password_set?, last_sign_in_at: u.portal_account.last_sign_in_at } }
end
