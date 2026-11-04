# Stop Library and Stop Assignment: every company user reads; stops, catchments, rider links and photo requests change
# with the plans permission; library requests are answered with the library permission. Feasibility Studies hold bus
# prices and break-even, so even reading them needs plans.
class StopPolicy < ApplicationPolicy
  def create? = permitted?(:plans)
  def update? = permitted?(:plans)
  def destroy? = permitted?(:plans)
  def review? = permitted?(:library)
  def feasibility? = user.convoy_admin? || user.can?(:plans)
  # Route prices and Route Charges (operator pay, school bills): finance.
  def money_setup? = permitted?(:finance)
  # A route's Bus Attendant settings and who is paid with no bus: plans or finance (the BA price: finance).
  def pay_setup? = permitted?(:plans) || permitted?(:finance)
end
