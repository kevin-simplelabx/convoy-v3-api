# Daily upkeep for every company: partitions for the next 3 months, the horizon pushed one day (rows for the new last
# day), and runs that ended marked completed.
module Occurrences
  class Daily < ApplicationService
    def call
      Partitions.ensure!(Date.current.beginning_of_month, (Date.current + Sync::HORIZON_DAYS + 90).end_of_month)
      Company.active.find_each do |company|
        ActsAsTenant.with_tenant(company) do
          Time.use_zone(company.timezone) do
            # Every trip running on the new last day, one-off trips booked far ahead too.
            Sync.call(trips: Trip.kept.active_between(Sync.horizon - 1, Sync.horizon).pluck(:id), routes: SchoolRoutes.running_ids,
                      from: Sync.horizon - 1, to: Sync.horizon)
            Complete.call
            TrackingLink.where(expires_at: ...7.days.ago).delete_all
            SchoolRuns::Purge.call
          end
        end
      end
    end
  end
end
