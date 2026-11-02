# Assign page helpers.
module Assignments
  # The latest pay agreed with an operator on a trip: [amount, basis] or nil.
  def self.agreed_pay(trip, operator_id)
    a = trip.assignments.where(operator_id:).where.not(pay_amount: nil).reorder(:created_at).last
    a && [ a.pay_amount, a.pay_basis ]
  end
end
