class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :role, :company_id, :created_at

  field :permissions do |user|
    user.effective_permissions
  end
end
