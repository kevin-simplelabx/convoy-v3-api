# Platform vehicle types: Convoy Admin adds, edits and removes them; a company Admin turns them on or off.
class VehicleTypePolicy < ApplicationPolicy
  def create? = user.convoy_admin?
  def update? = user.convoy_admin?
  def destroy? = user.convoy_admin?
  def toggle? = write? && (user.admin? || user.owner?)
end
