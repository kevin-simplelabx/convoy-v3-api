# Places the riders of an uploaded list on the map (OneMap). Tried again later when OneMap cannot be reached; after the
# last try the list is ready with those riders as No Location.
class SchoolRidersLocateJob < ApplicationJob
  queue_as :default

  retry_on Geo::OneMap::Unavailable, wait: 5.minutes, attempts: 5 do |job, _error|
    dataset = RiderDataset.unscoped.find_by(id: job.arguments.first) or next
    ActsAsTenant.with_tenant(dataset.company) { dataset.update!(status: "ready", unlocated_count: dataset.riders.where(lat: nil).count) }
  end

  def perform(dataset_id)
    dataset = RiderDataset.unscoped.find_by(id: dataset_id) or return
    ActsAsTenant.with_tenant(dataset.company) { SchoolRiders::Locate.call(dataset.riders, dataset:) }
  end
end
