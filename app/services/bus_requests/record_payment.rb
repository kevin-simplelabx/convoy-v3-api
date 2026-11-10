# Record First Invoice Paid: what the first invoice still owes is paid (a receipt in School Finance) and the request is
# Active (also from Lapsed while the child is still listed); a new child joins the route plans from the start date.
module BusRequests
  class RecordPayment < ApplicationService
    def initialize(req, method:, user:)
      @req = req
      @method = method.to_s.strip
      @user = user
    end

    def call
      raise Error, "Pick how it was paid" unless SchoolBills::RecordPayment::METHODS.include?(@method)

      bill = @req.first_bill
      raise Error, "This request has no first invoice to pay" unless bill
      raise Error, "The first invoice is already paid" if bill.paid?
      raise Error, "Only an accepted or lapsed request can be paid" unless %w[Accepted Lapsed].include?(@req.live_status)

      ApplicationRecord.transaction do
        owed = SchoolBills::Calc.call(bill, policy: nil).owed
        SchoolBills::RecordPayment.call(@req.school, [ [ bill, owed ] ], paid_on: Date.current, method: @method, user: @user)
        @req.update!(status: "Active")
        @req.log!("First invoice paid by #{@method}. Service is active", by: @user)
      end
      PlanSync.call(@req, user: @user)
      @req
    end
  end
end
