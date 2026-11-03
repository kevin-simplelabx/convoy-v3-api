# Ops Control: seen with the vehicles or plans permission, as in Convoy OS (a Convoy Admin sees it, read only);
# acknowledging an alert needs a company user with one of them.
class OpsControlPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:vehicles) || user.can?(:plans)
  def acknowledge? = permitted?(:vehicles) || permitted?(:plans)
end
