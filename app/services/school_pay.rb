# School Bus › School Finance › Operator Payments: who may prepare and approve school pay runs (Finance Settings), and
# what a pay run comes to (route pay plus additions, less deductions).
module SchoolPay
  module_function

  # { prepare:, approve:, set_up: } for a user. With nobody set up in Finance Settings anyone may prepare; only an
  # approver may approve, so a company with none must add one first.
  def rights(user)
    list = FinanceApprover.where(company_id: ActsAsTenant.current_tenant.id).to_a
    me = list.find { it.user_id == user.id }
    approvers = list.select(&:can_approve)
    { prepare: list.empty? || me.present?, approve: me&.can_approve || false, set_up: approvers.any?, approvers: approvers.size,
      maker: FinanceSetting.current.approval_maker? }
  end

  # The Operator Payments reference of an approved school pay run (a batch line points back to it).
  def ref(payout) = "school_payout:#{payout.id}"

  # Pay runs in an Operator Payments batch: payout id => { number, pay_date, notice_number, paid } — what the batch has
  # paid on the operator goes to its lines in proportion (all of it once the operator is paid in full).
  def batched(payouts)
    return {} if payouts.empty?

    lines = OperatorPayBatchLine.where(ref: payouts.map { ref(it) }).includes(operator_pay_batch_operator: %i[operator_pay_batch lines payments])
    lines.to_h do |l|
      bo = l.operator_pay_batch_operator
      total = bo.total
      paid = bo.paid >= total ? l.amount : (total.positive? ? (bo.paid * l.amount / total).round(2) : 0.to_d)
      [ l.ref.delete_prefix("school_payout:").to_i,
        { number: bo.operator_pay_batch.number, pay_date: bo.operator_pay_batch.pay_date, notice_number: bo.notice_number, paid: } ]
    end
  end

  # A Payment Voucher (port of pvView): the routes paid (as kept when sent to Finance), the lines, net, payments.
  def voucher(p)
    auto = p.auto_lines.map(&:symbolize_keys)
    lines = [ { details: "Route pay, #{p.routes_count.to_i} route#{'s' unless p.routes_count == 1}", amount: p.base.to_d } ] +
            (auto + p.adjustments.map { { kind: it.kind, route: it.route_label, reason: it.reason, sign: it.sign, amount: it.amount } }).map do |a|
              { details: [ a[:kind], a[:route], a[:reason] ].compact_blank.join(" | "), amount: a[:sign].to_i * a[:amount].to_d }
            end
    due = net(p.base, auto, p.adjustments.to_a)
    { id: p.id, title: "Payment Voucher", number: p.voucher_number || "Draft", month: p.month, school: p.school.name,
      pay_to: { id: p.operator.id, name: p.operator.name }, invoice_number: p.invoice_number, lines:, net: due,
      status: voucher_status(p), paid: p.paid_amount, balance: [ due - p.paid_amount, 0.to_d ].max.round(2),
      payments: p.payments.map { it.slice(:paid_on, :amount, :method, :reference) },
      prepared_by: p.prepared_by&.name, approved_by: p.approved_by&.name, approved_at: p.approved_at }
  end

  # A voucher is numbered at the first payment, so a part-paid run has one too: "Part Paid" until the net is paid.
  def voucher_status(p)
    net(p.base, p.auto_lines.map(&:symbolize_keys), p.adjustments.to_a) <= p.paid_amount + 0.005 ? "Paid" : "Part Paid"
  end

  # Route pay plus the lines (auto replacement lines, then those Ops added), each added or deducted.
  def net(base, auto, adjustments)
    lines = auto.sum(0.to_d) { it[:sign].to_i * it[:amount].to_d } + adjustments.sum(0.to_d) { it.sign * it.amount }
    (base.to_d + lines).round(2)
  end
end
