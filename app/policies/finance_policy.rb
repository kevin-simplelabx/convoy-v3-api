# Finance: seen with finance or finview, changed with finance. Finance Settings need finset; Vehicle Financials need
# vehfin. Unlock needs an Admin (admin, Super Admin or the Users permission). Convoy Admin: view only.
class FinancePolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:finance) || user.can?(:finview)
  def show? = index?
  def create? = permitted?(:finance)
  def update? = permitted?(:finance)
  def destroy? = permitted?(:finance)
  def settings? = user.convoy_admin? || user.can?(:finset)
  def update_settings? = permitted?(:finset)
  def unlock? = write? && (user.admin? || user.owner? || user.can?(:users))
  def vehicles? = user.convoy_admin? || user.can?(:vehfin)
  def update_vehicles? = permitted?(:vehfin)
end
