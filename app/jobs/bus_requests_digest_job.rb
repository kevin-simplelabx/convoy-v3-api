# 08:00 every day: the bus requests waiting, recorded as an email to each company's School Bus admins.
class BusRequestsDigestJob < ApplicationJob
  queue_as :default

  def perform
    Company.active.find_each do |c|
      ActsAsTenant.with_tenant(c) { Time.use_zone(c.timezone) { BusRequests::Digest.new(c).call } }
    end
  end
end
