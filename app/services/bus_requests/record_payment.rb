# Record First Invoice Paid: the bill is paid and the request Active (also from Lapsed while the child is still listed);
# a new child joins the route plans from the start date.
module BusRequests
  class RecordPayment < ApplicationService
    def initialize(req, method:, user:)
      @req = req
      @method = method.to_s.strip
      @user = user
    end

    def call
      bill = @req.first_bill
      raise Error, "This request has no first invoice to pay" unless bill
      raise Error, "The first invoice is already paid" if bill.paid?
      raise Error, "Only an accepted or lapsed request can be paid" unless %w[Accepted Lapsed].include?(@req.live_status)

      ApplicationRecord.transaction do
        bill.update!(status: "paid", paid_at: Time.current, method: @method.presence, recorded_by: @user)
        @req.update!(status: "Active")
        @req.log!("First invoice paid#{" by #{@method}" if @method.present?}. Service is active", by: @user)
      end
      PlanSync.call(@req, user: @user)
      @req
    end
  end
end
