# School Finance › Documents (port of docsVals; company-wide for Finance › Documents): the invoices, credit notes, debit
# notes, receipts and operator Payment Vouchers of the schools given, newest first (latest 300), by type, payer (a family or the school; a receipt
# shows under every payer whose bill it paid) and search, each with its status and the documents it links to.
module SchoolBills
  class Documents < ApplicationService
    TYPES = { "inv" => "Invoice", "cn" => "Credit Note", "dn" => "Debit Note", "rcp" => "Receipt", "pv" => "Payment Voucher" }.freeze
    LIMIT = 300

    def initialize(schools, type: nil, payer: nil, q: nil, today: Date.current)
      @schools = schools
      @type = type.presence
      @payer = payer.presence
      @q = q.to_s.strip.downcase.presence
      @today = today
    end

    def call
      bills = SchoolBill.issued.where(school: @schools).includes(:school, :lines, :waivers, payments: :receipt, notes: []).to_a
      docs = SchoolDocument.where(school: @schools).includes(:school, :school_bill, :applied_bill, payments: :school_bill).to_a
      policies = Calc.policies(@schools.map(&:id), today: @today)
      vouchers = SchoolPayout.where(school: @schools).where.not(voucher_number: nil).includes(:school, :operator, :payments, :adjustments).to_a
      all = bills.map { invoice(it, Calc.call(it, policy: policies[it.school_id], today: @today)) } + docs.map { doc(it) } + vouchers.map { voucher(it) }
      payers = all.reject { it[:payer_key].nil? }.map { [ it[:payer_key], it[:to] ] }.uniq(&:first).sort_by(&:last)
      counts = { "all" => all.size }.merge(TYPES.keys.index_with { |t| all.count { it[:type] == t } })
      list = all.select { (@type.nil? || it[:type] == @type) && payer?(it) && search?(it) }.sort_by { [ it[:date], it[:number] ] }.reverse
      { rows: list.first(LIMIT).map { it.except(:payer_keys, :search) }, count: list.size, counts:,
        payers: payers.map { |k, name| { key: k, name: } } }
    end

    def self.payer_key(payer, family_id) = payer == "school" ? "school" : "family:#{family_id}"

    private

    def payer?(d) = @payer.nil? || d[:payer_keys].include?(@payer)
    def search?(d) = @q.nil? || d[:search].compact.any? { it.downcase.include?(@q) }

    def invoice(b, c)
      key = Documents.payer_key(b.payer, b.family_id)
      receipts = b.payments.reject(&:voided?).filter_map { it.receipt&.number }
      links = [ (c.paid.positive? ? "Paid S$#{format('%.2f', c.paid)}" : nil), *receipts, *b.notes.reject(&:voided?).map(&:number) ].compact
      { type: "inv", id: b.id, number: b.number, date: b.issued_on, school_id: b.school_id, school: b.school.name, to: b.to_name, amount: b.total,
        status: c.status, tone: c.tone, links: links.join(", "), payer_key: key, payer_keys: [ key ], search: [ b.number, b.to_name ] }
    end

    def voucher(p)
      key = "operator:#{p.operator_id}"
      { type: "pv", id: p.id, number: p.voucher_number, date: p.voucher_on, school_id: p.school_id, school: p.school.name, to: p.operator.name,
        amount: p.paid_amount, status: SchoolPay.voucher_status(p), tone: "neutral", links: "#{p.month.strftime('%b %Y')} route pay#{" | Invoice #{p.invoice_number}" if p.invoice_number}",
        payer_key: key, payer_keys: [ key ], search: [ p.voucher_number, p.operator.name, p.invoice_number ] }
    end

    def doc(d)
      key = d.receipt? ? nil : Documents.payer_key(d.payer, d.family_id)
      keys = d.receipt? ? d.payments.map { Documents.payer_key(it.school_bill.payer, it.school_bill.family_id) }.uniq : [ key ]
      links = d.receipt? ? "Pays #{d.payments.map { it.school_bill.number }.uniq.join(', ')}" : "For #{d.school_bill&.number}"
      { type: d.doc_type, id: d.id, number: d.number, date: d.issued_on, school_id: d.school_id, school: d.school.name, to: d.bill_to, amount: d.total,
        status: d.status_text, tone: d.voided? ? "neutral" : { "cn" => "warning", "dn" => "info", "rcp" => "success" }[d.doc_type], links:,
        can_void: d.receipt? && !d.voided?, payer_key: key, payer_keys: keys, search: [ d.number, d.bill_to, d.reason, d.reference ] }
    end
  end
end
