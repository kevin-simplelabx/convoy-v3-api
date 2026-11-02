# HR (driver pay): seen with the finance or finview permission, changed with finance. Unlock (rate plans, pay schemes,
# bonuses) and Reopen Month need an Admin: admin / Super Admin or the Users permission. Convoy Admin: view only.
class PayPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:finance) || user.can?(:finview)
  def show? = index?
  def create? = permitted?(:finance)
  def update? = permitted?(:finance)
  def destroy? = permitted?(:finance)
  def lock? = permitted?(:finance)
  def unlock? = admin?
  def reopen? = admin?

  def admin? = write? && (user.admin? || user.owner? || user.can?(:users))
end
