# Daily: removes Convoy App accounts 30 days after Delete Account (the person did not sign in again). Company records
# (riders, bills, bookings) stay with the companies.
class AppAccountsPurgeJob < ApplicationJob
  queue_as :default

  def perform
    AppAccount.due_for_deletion.find_each(&:destroy!)
  end
end
