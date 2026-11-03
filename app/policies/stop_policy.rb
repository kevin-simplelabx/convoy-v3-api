# Stop Library and Stop Assignment: every company user reads; stops, catchments, rider links and photo requests change
# with the plans permission; library requests are answered with the library permission.
class StopPolicy < ApplicationPolicy
  def create? = permitted?(:plans)
  def update? = permitted?(:plans)
  def destroy? = permitted?(:plans)
  def review? = permitted?(:library)
  # Route prices and Route Charges (operator pay, school bills): finance.
  def money_setup? = permitted?(:finance)
end
