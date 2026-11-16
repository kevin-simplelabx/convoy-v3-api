# A bus request of a Family changed status (accepted with an offer, waitlisted, declined, active, stopping...): every adult
# of the Family is told, except the one who did it in the app (withdraw, agree). Called by BusRequest after commit, so every
# writer (OS Accept / Decide / Record Payment, the daily job, the app) is covered. Tap opens Application Status.
module ConvoyApp
  module Alerts
    class Requests < ApplicationService
      QUIET = %w[Requested].freeze

      def initialize(request)
        @req = request
      end

      def call
        return 0 if @req.household_id.nil? || QUIET.include?(@req.status)

        company = @req.company
        Parents.within(company) do
          req = BusRequest.includes(:registration_bill, :academic_year, school: :company).find(@req.id)
          ids = Alerts.without_actor(Alerts.adults_of([ req.household_id ])[req.household_id] || [])
          return 0 if ids.empty?

          badge = Parents::Present.badge(req)
          body = Parents::Present.line(req, req.live_status, company.name)
          Alerts.write(Alerts.rows_for(ids, kind: "request_update", title: "#{req.child_name} · #{badge[:label]}", body:, company_id: company.id,
                                            dependant_id: req.dependant_id, target: "school_request", target_id: req.id,
                                            dedupe_key: "request:#{req.id}:#{req.status}:#{req.updated_at.to_i}"))
        end
      end
    end
  end
end
