# Insurance: vehicles permission; only the current policy is edited, only past ones deleted.
class VehicleInsurancePolicyPolicy < FleetPolicy
  def update? = super && record.current?
  def destroy? = super && !record.current?
  def renew? = permitted?(:vehicles)
end
