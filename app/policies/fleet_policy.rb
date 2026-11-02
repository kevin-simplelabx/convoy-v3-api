# Fleet records (vehicles, drivers, operators, attendants, teams): read by everyone, changed with the vehicles permission.
class FleetPolicy < ApplicationPolicy
  def create? = permitted?(:vehicles)
  def update? = permitted?(:vehicles)
  def destroy? = permitted?(:vehicles)
end
