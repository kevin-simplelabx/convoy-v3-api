# Log cards: vehicles permission; only Past Log Cards can be deleted.
class VehicleLogCardPolicy < FleetPolicy
  def destroy? = super && !record.current?
  def resolve_plate? = update?
end
