# Finance > Documents: every document issued across the company, newest first (latest 300): client invoices and credit
# notes, operator payment notices, and the School Bus documents of the schools the user may open (bills, credit and
# debit notes, receipts, payment vouchers; one school with school_id).
module Finance
  class Documents < ApplicationService
    TYPES = { "invoice" => "Invoice", "credit_note" => "Credit Note", "payment_notice" => "Payment Notice", "school_invoice" => "School Bus Invoice",
              "school_credit_note" => "School Bus Credit Note", "debit_note" => "Debit Note", "receipt" => "Receipt",
              "payment_voucher" => "Payment Voucher" }.freeze
    SCHOOL_TYPES = { "inv" => "school_invoice", "cn" => "school_credit_note", "dn" => "debit_note", "rcp" => "receipt", "pv" => "payment_voucher" }.freeze
    LIMIT = 300

    def initialize(type: nil, q: nil, schools: School.none)
      @type = type.presence
      @q = q.to_s.strip.downcase.presence
      @schools = schools
    end

    def call
      all = invoices + notices + school_docs
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

    def school_docs
      SchoolBills::Documents.call(@schools.to_a)[:rows].map do |d|
        d.slice(:id, :number, :date, :to, :amount, :status, :school_id, :school).merge(type: SCHOOL_TYPES[d[:type]], school_type: d[:type])
      end
    end

    def notice_status(bo)
      return "paid" if bo.left <= 0

      bo.paid.positive? ? "part_paid" : "issued"
    end
  end
end
