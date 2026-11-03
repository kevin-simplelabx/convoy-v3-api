# Live Map: seen with the vehicles or plans permission, as in Convoy OS (read only; a Convoy Admin sees it too).
class LiveMapPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:vehicles) || user.can?(:plans)
  def show? = index?
end
