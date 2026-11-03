# Every morning: Convoy drafts each school's bills for the coming billing period once its draft day has come, for every
# company. Finance checks and issues them in Collections.
class SchoolBillsDailyJob < ApplicationJob
  queue_as :default

  def perform
    Company.active.find_each do |c|
      ActsAsTenant.with_tenant(c) { Time.use_zone(c.timezone) { SchoolBills::Auto.call } }
    end
  end
end
