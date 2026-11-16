# Record First Invoice Paid: what the first invoice still owes is paid (a receipt in School Finance) and the request is
# Active (also from Lapsed while the child is still listed); a new child joins the route plans from the start date.
module BusRequests
  class RecordPayment < ApplicationService
    # The Convoy App pays for the parent: no user, source "app", by = the adult's name; amount = what it collected (late fee
    # included), else what the invoice owes before any late fee.
    def initialize(req, method:, user: nil, source: "console", admin_fee: 0, by: nil, amount: nil, reference: nil)
      @req = req
      @method = method.to_s.strip
      @user = user
      @source = source
      @admin_fee = admin_fee
      @by = by
      @amount = amount
      @reference = reference
    end

    def call
      raise Error, "Pick how it was paid" unless SchoolBills::RecordPayment::METHODS.include?(@method)

      bill = @req.first_bill
      raise Error, "This request has no first invoice to pay" unless bill
      raise Error, "The first invoice is already paid" if bill.paid?
      raise Error, "Only an accepted or lapsed request can be paid" unless %w[Accepted Lapsed].include?(@req.live_status)

      ApplicationRecord.transaction do
        owed = @amount || SchoolBills::Calc.call(bill, policy: nil).owed
        SchoolBills::RecordPayment.call(@req.school, [ [ bill, owed ] ], paid_on: Date.current, method: @method, user: @user, source: @source, admin_fee: @admin_fee, reference: @reference)
        @req.update!(status: "Active")
        @req.log!("First invoice paid by #{@method}. Service is active", by: @user || @by)
      end
      PlanSync.call(@req, user: @user)
      @req
    end
  end
end
