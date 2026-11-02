# Re-syncs a company's trips in the background (calendar, public holiday or company setting changed).
class OccurrenceSyncJob < ApplicationJob
  queue_as :default

  def perform(company_id, trip_ids, from = nil, to = nil, route_ids = [])
    company = Company.find(company_id)
    ActsAsTenant.with_tenant(company) do
      Time.use_zone(company.timezone) do
        Occurrences::Sync.call(trips: trip_ids, routes: route_ids, from: from && Date.parse(from.to_s), to: to && Date.parse(to.to_s))
      end
    end
  end
end
