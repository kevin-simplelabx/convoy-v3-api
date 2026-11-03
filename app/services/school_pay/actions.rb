# What Ops and Finance do with an operator's pay run for a school's month (port of payrunVals' actions): add or remove a
# line (a covered route adds to one operator and deducts from the other), the operator's invoice number, Send to
# Finance (route pay, routes and replacement lines kept), Recall, Send Back, Approve (another approver when
# maker-checker is on), Reopen, and Pay (the first payment numbers its Payment Voucher).
module SchoolPay
  class Actions
    Error = ApplicationService::Error

    def initialize(school, month, operator, user:, now: Time.current)
      @school = school
      @month = month.beginning_of_month
      @operator = operator
      @user = user
      @now = now
      @rights = SchoolPay.rights(user)
    end

    def payout = @payout ||= SchoolPayout.find_or_create_by!(school: @school, month: @month, operator: @operator)

    def add_line(p, files: [])
      prepare!
      sign = SchoolPayoutAdjustment::KINDS[p[:kind]] or raise Error, "Pick the type of line"
      raise Error, "Enter the amount" unless p[:amount].to_d.positive?
      raise Error, "Enter a reason" if p[:reason].to_s.strip.empty?

      on = date(p[:adj_on]) or raise Error, "Pick the date"
      editable!(payout)
      other = p[:kind] == "Covered another route" && p[:paired_operator_id].present? ? Operator.find(p[:paired_operator_id]) : nil
      pair = other && SchoolPayout.find_or_create_by!(school: @school, month: @month, operator: other)
      raise Error, "#{other.name} is already with Finance or approved. Recall or reopen it first to add the matching deduction" if pair&.locked?

      ApplicationRecord.transaction do
        line = payout.adjustments.create!(kind: p[:kind], sign:, adj_on: on, route_label: p[:route].presence, amount: p[:amount].to_d.round(2),
                                          reason: p[:reason].to_s.strip, paired_operator: other, created_by: @user)
        files.each { line.files.create!(file: it, name: it.original_filename) }
        if pair
          match = pair.adjustments.create!(kind: "Route covered by #{@operator.name}", sign: -1, adj_on: on, route_label: p[:route].presence,
                                           amount: line.amount, reason: line.reason, paired_operator: @operator, pair: line, created_by: @user)
          line.update!(pair: match)
          pair.update!(prepared_by: @user)
        end
        payout.update!(prepared_by: @user)
        line
      end
    end

    def remove_line(id)
      prepare!
      line = payout.adjustments.find(id)
      editable!(payout)
      line.destroy!
    end

    def invoice_number(value)
      prepare!
      editable!(payout)
      payout.update!(invoice_number: value.to_s.strip.presence)
    end

    def send_to_finance
      prepare!
      raise Error, "Only an open pay run can be sent to Finance" unless payout.draft? && payout.payments.none?

      payout.update!(status: "ready", **snapshot, sent_by: @user, sent_at: @now, prepared_by: payout.prepared_by || @user)
    end

    def recall
      prepare!
      raise Error, "Only a pay run with Finance can be recalled" unless payout.status == "ready" && payout.payments.none?

      payout.update!(status: "draft", base: nil, routes_count: nil, auto_lines: [], sent_by: nil, sent_at: nil)
    end

    def send_back
      approver!
      raise Error, "Only a pay run with Finance can be sent back" unless payout.status == "ready" && payout.payments.none?

      payout.update!(status: "draft", base: nil, routes_count: nil, auto_lines: [], sent_by: nil, sent_at: nil, returned_by: @user, returned_at: @now)
    end

    def approve
      approver!
      raise Error, "Only a pay run with Finance can be approved" unless payout.status == "ready" && payout.payments.none?

      payout.update!(status: "approved", approved_by: @user, approved_at: @now)
    end

    def reopen
      raise Error, "Only an approver can reopen a pay run" unless @rights[:approve]
      raise Error, "Only an approved pay run with no payment can be reopened" unless payout.status == "approved" && payout.payments.none?
      raise Error, "This pay run is in an Operator Payments batch" if OperatorPayBatchLine.exists?(ref: SchoolPay.ref(payout))

      payout.update!(status: "draft", base: nil, routes_count: nil, auto_lines: [], approved_by: nil, approved_at: nil, sent_by: nil, sent_at: nil)
    end

    def pay(p)
      raise Error, "Approve the pay run before paying it" unless payout.status == "approved"
      if (b = SchoolPay.batched([ payout ])[payout.id])
        raise Error, "This pay run is in payment batch #{b[:number]}. Record its payment in Finance, Operator Payments"
      end

      amount = p[:amount].to_d
      on = date(p[:paid_on]) or raise Error, "Pick the date paid"
      raise Error, "Enter the amount paid" unless amount.positive?
      raise Error, "Pick how it was paid" unless SchoolPayoutPayment::METHODS.include?(p[:method])

      left = SchoolPay.net(payout.base, payout.auto_lines.map(&:symbolize_keys), payout.adjustments.to_a) - payout.paid_amount
      raise Error, "Amount is more than the S$#{format('%.2f', left)} left to pay" if amount > left + 0.005

      ApplicationRecord.transaction do
        payout.payments.create!(paid_on: on, amount: amount.round(2), method: p[:method], reference: p[:reference].to_s.strip.presence, recorded_by: @user)
        payout.update!(voucher_number: payout.voucher_number || Finance::Numbering.next!("pv", date: on), voucher_on: on)
      end
    end

    private

    def prepare! = (@rights[:prepare] or raise Error, "Only preparers or approvers in Finance Settings can do this")

    def approver!
      raise Error, "Add approvers in Finance Settings first" unless @rights[:set_up]
      raise Error, "Only an approver can do this" unless @rights[:approve]
      raise Error, "Maker-checker is on. Another approver must check what you sent" if @rights[:maker] && payout.sent_by_id == @user.id
    end

    def editable!(p) = (p.locked? and raise Error, "This pay run is with Finance or approved. Recall or reopen it first")

    # The route pay, routes and replacement lines when Ops sends it to Finance.
    def snapshot
      cost = Cost.call(@school, @month)
      live = cost[:by_operator][@operator.id] || { routes: 0, amount: 0 }
      { base: live[:amount].round(2), routes_count: live[:routes], auto_lines: cost[:auto][@operator.id] || [] }
    end

    def date(v)
      v.presence && Date.parse(v.to_s)
    rescue Date::Error
      nil
    end
  end
end
