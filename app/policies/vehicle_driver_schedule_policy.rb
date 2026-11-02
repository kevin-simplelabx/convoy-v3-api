# Changing the default driver: vehicles permission; only entries that have not started can be removed.
class VehicleDriverSchedulePolicy < FleetPolicy
  def destroy? = super && record.starts_on > Date.current
end
