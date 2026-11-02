# Every few minutes: runs that ended become completed, in every company.
class OccurrenceCompleteJob < ApplicationJob
  queue_as :default

  def perform
    Company.active.find_each { |c| ActsAsTenant.with_tenant(c) { Occurrences::Complete.call } }
  end
end
