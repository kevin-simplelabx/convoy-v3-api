# Settings > Users: seen and changed with the Users permission (Convoy Admin: view only). Which user may act on which
# (Super Admins, yourself) is checked by Users::Save / Users::Act, so the answer explains itself (422).
class UserPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:users)
  def show? = index?
  def roles? = index?
  def create? = permitted?(:users)
  def update? = permitted?(:users)
  def destroy? = permitted?(:users)
  def suspend? = permitted?(:users)
  def activate? = permitted?(:users)
  # Profile: everyone edits their own (Convoy Admin too).
  def profile? = record == user

  def permitted_attributes_for_create = [ :name, :email, :password, *permitted_attributes_for_update ]
  def permitted_attributes_for_update = [ :owner, :all_schools, { permissions: [], school_ids: [] } ]
  def permitted_attributes_for_profile = %i[display_name mobile avatar remove_avatar]

  class Scope < Scope
    def resolve
      scope.kept.where(company_id: ActsAsTenant.current_tenant&.id)
    end
  end
end
