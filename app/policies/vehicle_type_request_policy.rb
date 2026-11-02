# Request a New Type: company users with the vehicles permission send; Convoy Admin adds or declines.
class VehicleTypeRequestPolicy < ApplicationPolicy
  def create? = permitted?(:vehicles)
  def approve? = user.convoy_admin?
  def decline? = user.convoy_admin?

  class Scope < Scope
    def resolve = user.convoy_admin? ? scope.all : scope.where(company_id: user.company_id)
  end
end
