# School Bus › Schools: every company user lists the schools they may open (the school picker of the School Bus pages);
# adding a school and its Route Labels need the schools permission. Users without every school see their own schools.
class SchoolPolicy < ApplicationPolicy
  def create? = permitted?(:schools)
  def update_labels? = permitted?(:schools)
  # Rider Data (upload, delete) and Add Rider.
  def manage_riders? = permitted?(:schools)
  # Year Setup (calendar, holidays, sessions, levels, bus attendants): plans or schools. Delete Year: Admins (users).
  def setup? = permitted?(:plans) || permitted?(:schools)
  def delete_year? = permitted?(:users)
  # Money steps (Bus Fares, Extra Charges, Policy, Payment Methods, Operator Pay): finance.
  def money_setup? = permitted?(:finance)
  # Operator Pay is seen with finance or finview (Convoy OS canFin).
  def money_view? = user.convoy_admin? || user.can?(:finance) || user.can?(:finview)

  class Scope < Scope
    def resolve
      return scope.all if user.convoy_admin? || user.every_school?

      scope.where(id: user.user_schools.select(:school_id))
    end
  end
end
