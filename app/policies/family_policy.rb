# Families & Riders: seen with plans, schools or finance (Convoy OS); changed by a company user with one of them.
class FamilyPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || allowed?
  def show? = index?
  def create? = write? && allowed?
  def update? = create?
  def destroy? = create?

  private

  def allowed? = user.can?(:plans) || user.can?(:schools) || user.can?(:finance)
end
