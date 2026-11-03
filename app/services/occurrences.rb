# Occurrence engine: Generator (what the rows should be), Sync (write them), Partitions, Fleet; rules in .notes/domains/occurrences.md.
module Occurrences
  # Vehicle, its driver on the date (at the run's start minute), its operator and the operator cost when the bus is not ours.
  def self.vehicle_attrs(fleet, trip, vehicle_id, date, minute = nil)
    driver = vehicle_id && fleet.driver_on(vehicle_id, date, minute)
    {
      vehicle_id:, driver_id: driver.is_a?(Driver) ? driver.id : nil,
      operator_driver_id: driver.is_a?(OperatorDriver) ? driver.id : nil, operator_id: fleet.operator_of(vehicle_id),
      operator_cost: vehicle_id && trip && !fleet.own?(vehicle_id) ? trip.operator_cost : nil
    }
  end
end
