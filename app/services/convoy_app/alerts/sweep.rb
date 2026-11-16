# AppAlertsJob (every minute): notices in force and today's School Bus runs, company by company (only companies with a child
# linked to a Family or an accepted staff rider), each inside its tenant and time zone. Returns how many alerts were written.
module ConvoyApp
  module Alerts
    class Sweep < ApplicationService
      def initialize(now: Time.current)
        @now = now
      end

      def call
        ids = ActsAsTenant.without_tenant do
          FamilyRider.where.not(dependant_id: nil).distinct.pluck(:company_id) | ClientRider.where(status: "accepted").distinct.pluck(:company_id)
        end
        Company.active.where(id: ids).order(:id).sum do |company|
          Parents.within(company) { Notices.call(now: @now) + SchoolRuns.call(now: @now) }
        end
      end
    end
  end
end
