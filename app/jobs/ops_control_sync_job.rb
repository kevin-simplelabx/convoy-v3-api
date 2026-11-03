# Every minute: Ops Control checks the runs of every company, so alerts are raised, cleared and escalated even when no one
# has the board open.
class OpsControlSyncJob < ApplicationJob
  queue_as :default

  def perform
    Company.active.find_each do |c|
      ActsAsTenant.with_tenant(c) { Time.use_zone(c.timezone) { OpsControl::Sync.call } }
    end
  end
end
