class UserBlueprint < ApplicationBlueprint
  fields :name, :display_name, :shown_name, :email, :mobile, :mobile_display, :role, :role_label, :owner, :status, :company_id, :initials

  field(:avatar) { |user| user.avatar_info }
  field(:permissions) { |user| user.effective_permissions }

  # Settings > Users rows and the user form. Pass actor: (the signed-in user) for the row buttons.
  view :manage do
    fields :all_schools, :created_at

    field(:every_school) { |user| user.every_school? }
    field(:schools) { |user| user.every_school? ? [] : user.schools.sort_by(&:name).map { |s| { id: s.id, name: s.short } } }
    field(:created_by) { |user| user.created_by && { id: user.created_by.id, name: user.created_by.shown_name } }
    # Edit: needs Users; a Super Admin row only for a Super Admin. Suspend / Delete: also never yourself.
    field(:can_edit) { |user, options| user.can_be_edited_by?(options[:actor]) }
    field(:can_act) { |user, options| user.can_be_edited_by?(options[:actor]) && user.id != options[:actor]&.id }
  end
end
