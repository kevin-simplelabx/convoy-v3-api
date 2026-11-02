class UserBlueprint < ApplicationBlueprint
  fields :name, :email, :mobile, :role, :owner, :status, :company_id, :initials

  field(:avatar) { |user| user.avatar_info }
  field(:permissions) { |user| user.effective_permissions }
end
