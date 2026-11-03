# Bus Service Requests: seen with plans, schools or finance (Convoy OS); reviewed by a company user with plans or schools.
class BusRequestPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:plans) || user.can?(:schools) || user.can?(:finance)
  def show? = index?
  def create? = write? && (user.can?(:plans) || user.can?(:schools))
  def update? = create?
end
