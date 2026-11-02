# Finance > Documents: every document issued across the company, newest first (latest 300): client invoices and credit
# notes, and operator payment notices. School Bus documents (bills, receipts, vouchers) join with the School Bus menu.
module Finance
  class Documents < ApplicationService
    TYPES = { "invoice" => "Invoice", "credit_note" => "Credit Note", "payment_notice" => "Payment Notice" }.freeze
    LIMIT = 300

    def initialize(type: nil, q: nil)
      @type = type.presence
      @q = q.to_s.strip.downcase.presence
    end

    def call
      all = invoices + notices
      counts = TYPES.keys.index_with { |t| all.count { |d| d[:type] == t } }
      list = all.select { |d| (@type.nil? || d[:type] == @type) && (@q.nil? || [ d[:number], d[:to] ].compact.any? { |s| s.downcase.include?(@q) }) }
                .sort_by { |d| [ d[:date], d[:number] ] }.reverse
      { rows: list.first(LIMIT), count: list.size, counts: }
    end

    private

    def invoices
      ClientInvoice.where.not(number: nil).includes(:payments, :credit_notes).map do |i|
        { type: i.kind, id: i.id, number: i.number, date: i.issued_on, to: i.bill_to_name, amount: i.total,
          status: i.credit_note? ? i.status : i.display_status }
      end
    end

    def notices
      OperatorPayBatchOperator.where.not(notice_number: nil).joins(:operator_pay_batch)
                              .merge(OperatorPayBatch.where(company_id: ActsAsTenant.current_tenant.id))
                              .includes(:operator, :lines, :payments, :operator_pay_batch).map do |bo|
        { type: "payment_notice", id: bo.id, number: bo.notice_number, date: bo.operator_pay_batch.pay_date, to: bo.operator.name,
          amount: bo.total, status: notice_status(bo), batch_id: bo.operator_pay_batch_id }
      end
    end

    def notice_status(bo)
      return "paid" if bo.left <= 0

      bo.paid.positive? ? "part_paid" : "issued"
    end
  end
end
