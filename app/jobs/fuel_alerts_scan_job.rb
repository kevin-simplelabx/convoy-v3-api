# Daily: Needs a Look for every company with fuel entries (trends move with the date, findings age out after 90 days).
class FuelAlertsScanJob < ApplicationJob
  queue_as :default

  def perform
    Company.where(id: ActsAsTenant.without_tenant { FuelEntry.distinct.pluck(:company_id) }).find_each do |company|
      ActsAsTenant.with_tenant(company) { FuelAlerts::Scan.call }
    end
  end
end
