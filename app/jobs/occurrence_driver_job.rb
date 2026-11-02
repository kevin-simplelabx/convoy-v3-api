# The default driver of a vehicle changed: future runs on it from a date take the driver the schedule now says.
class OccurrenceDriverJob < ApplicationJob
  queue_as :default

  def perform(company_id, vehicle_id, from)
    ActsAsTenant.with_tenant(Company.find(company_id)) { Occurrences::RefreshDrivers.call(vehicle_id:, from: Date.parse(from)) }
  end
end
