# Operator Payments: Approve and Set Pay Date (items pool into the open batch of that date, else a new one), Ad Hoc
# Payment (its own batch), change a batch's pay date (pooling into an open batch of the new date), Cancel Batch (items
# go back to requests), record payments, Mark All Paid, and the bank file (issues each operator's payment notice).
# Only approvers in Finance Settings may do these (anyone with finance when no approver is set).
module OperatorPay
  class Batches < ApplicationService
    FAST_LIMIT = 200_000

    def initialize(user:, today: Date.current)
      @user = user
      @today = today
      can_run!
    end

    def approve!(refs:, pay_date: nil, batch_id: nil)
      items = pick(refs)
      raise Error, "Select the requests to approve" if items.empty?

      OperatorPayBatch.transaction do
        batch = batch_id ? open_batch!(batch_id) : batch_for(date!(pay_date))
        add(batch, items)
        batch
      end
    end

    def ad_hoc!(operator:, pay_date:, refs: [], extra: nil)
      date = date!(pay_date)
      items = pick(refs).select { |i| i.operator.id == operator.id }
      OperatorPayBatch.transaction do
        if extra && (extra[:amount].present? || extra[:description].present?)
          raise Error, "Describe the extra line" if extra[:description].blank?

          item = OperatorPayItem.create!(operator:, description: extra[:description], item_on: date, amount: extra[:amount], created_by: @user)
          items += OperatorPay::Due.call(operator_id: operator.id).select { |i| i.ref == "item:#{item.id}" }
        end
        raise Error, "The payment must be more than S$0" if items.sum { |i| i.amount.to_d } <= 0

        batch = new_batch(date, kind: "adhoc")
        add(batch, items)
        batch
      end
    end

    def change_date!(batch, pay_date, merge: false)
      raise Error, "#{batch.number} has gone to the bank or has payments" unless batch.open?

      date = date!(pay_date)
      other = OperatorPayBatch.kind_batch.where(pay_date: date).where.not(id: batch.id).find(&:open?)
      if other && batch.kind_batch?
        raise Error, "#{other.number} already pays on #{date.strftime('%-d %b %Y')}. Pool #{batch.number} into it?" unless merge

        OperatorPayBatch.transaction do
          batch.batch_operators.each { |bo| move_lines(bo, other) }
          batch.destroy!
        end
        return other
      end
      batch.update!(pay_date: date)
      batch
    end

    def cancel!(batch)
      raise Error, "#{batch.number} has payments, so it can't be cancelled" if batch.paid.positive?

      batch.update!(audit_comment: "Cancelled #{batch.number}")
      batch.destroy!
    end

    # Take out of batch: an operator leaves an open batch with all its lines; its items go back to Payment Requests (an
    # ad hoc extra line too: it is an extra item). The batch goes when no operator is left. Returns the batch, or nil.
    def remove_operator!(batch, batch_operator)
      raise Error, "#{batch.number} has gone to the bank or has payments" unless batch.open?

      OperatorPayBatch.transaction do
        batch.update!(audit_comment: "Took #{batch_operator.operator.name} out of #{batch.number}")
        batch_operator.destroy!
        if batch.batch_operators.reload.none?
          batch.destroy!
          nil
        else
          batch
        end
      end
    end

    def pay!(batch_operator, paid_on:, amount:, method:, reference: nil)
      amount = amount.to_d
      raise Error, "Enter the amount paid" unless amount.positive?
      raise Error, "Amount is more than the #{money(batch_operator.left)} left to pay" if amount > batch_operator.left + 0.005

      batch_operator.payments.create!(paid_on: paid_on.presence || @today, amount:, method:, reference:, recorded_by: @user)
    end

    # Mark All Paid: what is left of every operator, paid on the date given; the reference is the PN plus the bank's reference.
    def mark_all_paid!(batch, paid_on:, reference: nil)
      raise Error, "Pick the date paid" if paid_on.blank?

      OperatorPayBatch.transaction do
        batch.batch_operators.each do |bo|
          next unless bo.left.positive?

          bo.payments.create!(paid_on:, amount: bo.left, method: method_of(bo), reference: [ bo.notice_number, reference.to_s.strip ].compact_blank.join(" "),
                              recorded_by: @user)
        end
      end
    end

    # The bank file: checks every operator can be paid (details, FAST limit), issues payment notices (PN) and locks the batch.
    def bank_file!(batch, transfer_type:)
      raise Error, "Pick FAST or GIRO" unless %w[FAST GIRO].include?(transfer_type)

      batch.batch_operators.each do |bo|
        pays = bo.operator.decorate.pays_by
        raise Error, "Add payment details for #{bo.operator.name} in Managed Operators first" if pays[:warn]
        if transfer_type == "FAST" && pays[:method] == "Bank Transfer" && bo.left > FAST_LIMIT
          raise Error, "FAST allows up to S$200,000 per payment. Use GIRO for #{bo.operator.name}"
        end
      end
      OperatorPayBatch.transaction do
        batch.batch_operators.each do |bo|
          pays = bo.operator.decorate.pays_by
          bo.update!(notice_number: bo.notice_number || Finance::Numbering.next!("pn", date: batch.pay_date), pay_method: pays[:method], pay_to: pays[:to])
        end
        batch.update!(transfer_type:, bank_file_at: batch.bank_file_at || Time.current, bank_file_by: @user)
      end
      batch
    end

    # The bank CSV (columns of the prototype): operators with something left to pay.
    def self.csv(batch)
      require "csv"
      CSV.generate do |csv|
        csv << [ "Value Date", "Payee Name", "Payment Type", "Bank Name", "Bank Code", "Branch Code", "Account Number", "Account Name",
                 "PayNow Proxy Type", "PayNow Proxy", "Amount (SGD)", "Reference", "Payee Email" ]
        batch.batch_operators.each do |bo|
          next unless bo.left.positive?

          op = bo.operator
          paynow = bo.pay_method == "PayNow UEN"
          csv << [ batch.pay_date.iso8601, op.name, paynow ? "PayNow" : batch.transfer_type, (op.bank&.name unless paynow), (op.bank_code unless paynow),
                   (op.branch_code unless paynow), (op.account_number unless paynow), (op.account_name unless paynow), (paynow ? "UEN" : nil),
                   (op.paynow_uen if paynow), format("%.2f", bo.left), bo.notice_number, op.email ]
        end
      end
    end

    private

    def can_run!
      approvers = FinanceApprover.where(company_id: ActsAsTenant.current_tenant.id, can_approve: true)
      return if approvers.none? || approvers.exists?(user_id: @user.id)

      raise Error, "Only approvers in Finance Settings can approve requests, set pay dates and record payments"
    end

    def pick(refs)
      refs = Array(refs).map(&:to_s)
      items = OperatorPay::Due.call.select { |i| refs.include?(i.ref) }
      not_ready = items.reject(&:ready)
      raise Error, "#{not_ready.size} of the items are not ready: #{not_ready.first.why}" if not_ready.any?

      items
    end

    def date!(value)
      date = value.presence && Date.parse(value.to_s)
      raise Error, "Pick the pay date" unless date
      raise Error, "Pick today or a later pay date" if date < @today

      date
    rescue Date::Error
      raise Error, "Pick the pay date"
    end

    def batch_for(date) = OperatorPayBatch.kind_batch.where(pay_date: date).order(:id).find(&:open?) || new_batch(date)

    def open_batch!(id)
      batch = OperatorPayBatch.find(id)
      raise Error, "#{batch.number} has gone to the bank, so this starts a new batch" unless batch.open? && batch.kind_batch?

      batch
    end

    def new_batch(date, kind: "batch")
      OperatorPayBatch.create!(number: Finance::Numbering.next!("pb", date:), kind:, pay_date: date, created_by: @user)
    end

    def add(batch, items)
      items.group_by(&:operator).each do |op, list|
        bo = batch.batch_operators.find_or_create_by!(operator: op)
        list.each do |i|
          bo.lines.create!(ref: i.ref, source: i.source, description: i.description, details: i.details, item_on: i.item_on,
                           amount: i.amount, approved_by: @user, approved_at: Time.current)
        end
      end
      batch.update!(audit_comment: "Approved #{items.size} items")
    end

    def move_lines(bo, other)
      target = other.batch_operators.find_or_create_by!(operator: bo.operator)
      bo.lines.update_all(operator_pay_batch_operator_id: target.id) # rubocop:disable Rails/SkipsModelValidations
    end

    def method_of(bo)
      { "PayNow UEN" => "PayNow", "Bank Transfer" => bo.operator_pay_batch.transfer_type || "Bank Transfer" }.fetch(bo.pay_method || bo.operator.decorate.pays_by[:method], "Bank Transfer")
    end

    def money(v) = "S$#{format('%.2f', v)}"
  end
end
