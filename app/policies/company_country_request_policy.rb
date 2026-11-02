# Request a Country Change: company users with the Users permission send and withdraw; Convoy Admin approves or declines.
class CompanyCountryRequestPolicy < ApplicationPolicy
  def create? = permitted?(:users)
  def withdraw? = permitted?(:users) && record.company_id == user.company_id
  def approve? = user.convoy_admin?
  def decline? = user.convoy_admin?

  class Scope < Scope
    def resolve = user.convoy_admin? ? scope.all : scope.where(company_id: user.company_id)
  end
end
