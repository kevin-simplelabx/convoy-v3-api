# Application Status › Withdraw Request: allowed until the service is confirmed (Active) or declined. An accepted request
# withdrawn before its first invoice is paid tells the company to take the child off the rider list (BusRequests.end_of).
module ConvoyApp
  module Parents
    class Withdraw < ApplicationService
      ALLOWED = [ "Requested", "Under Review", "Accepted", "Waitlisted", "Lapsed" ].freeze

      def initialize(req, account:)
        @req = req
        @account = account
      end

      def call
        raise Error, "Only a bus service application can be withdrawn here" unless @req.kind == "new"

        @req.with_lock do
          # Checked on the row as it is now: a first invoice paid meanwhile made it Active.
          raise Error, "This request can no longer be withdrawn" unless ALLOWED.include?(@req.live_status)

          @req.update!(status: "Withdrawn")
          @req.log!("Withdrawn by the parent (#{@account.display_name})", by: "Parent")
        end
        @req
      end
    end
  end
end
