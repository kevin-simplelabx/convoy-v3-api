# Every morning: confirmed changes of service and address reach the rider records on their dates, and renewed riders
# move to their new level, for every company.
class BusRequestsDailyJob < ApplicationJob
  queue_as :default

  def perform
    Company.active.find_each do |c|
      ActsAsTenant.with_tenant(c) { Time.use_zone(c.timezone) { BusRequests::RiderSync.call } }
    end
  end
end
