# Recompute a vehicle's fuel entries (driver of the day) after its default driver schedule changes.
class FuelRecomputeJob < ApplicationJob
  queue_as :default

  def perform(company_id, vehicle_id)
    ActsAsTenant.with_tenant(Company.find(company_id)) do
      vehicle = Vehicle.with_discarded.find_by(id: vehicle_id)
      FuelEntries::Recompute.call(vehicle:) if vehicle && FuelEntry.exists?(vehicle_id:)
    end
  end
end
