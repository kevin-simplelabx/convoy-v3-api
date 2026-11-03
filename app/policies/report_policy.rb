# Reports: seen with the vehicles, finance or finview permission (read only).
class ReportPolicy < ApplicationPolicy
  def index? = user.convoy_admin? || user.can?(:vehicles) || user.can?(:finance) || user.can?(:finview)
  def show? = index?
end
