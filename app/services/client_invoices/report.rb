# Client Invoices: KPIs (Owed to You, Overdue, Invoiced and Collected this month), aging buckets, balances by billing
# entity (Clients card) and the Statement of Account of an entity.
module ClientInvoices
  class Report < ApplicationService
    BUCKETS = [ [ "current", "Current", ..0 ], [ "1_30", "1 to 30 days", 1..30 ], [ "31_60", "31 to 60 days", 31..60 ],
                [ "61_90", "61 to 90 days", 61..90 ], [ "over_90", "Over 90 days", 91.. ] ].freeze

    def initialize(month: Date.current, today: Date.current)
      @month = month.beginning_of_month
      @today = today
    end

    def call
      open = issued.select { |i| i.balance > 0.005 }
      { owed: open.sum(0.to_d, &:balance), overdue: open.select { |i| i.due_on && i.due_on < @today }.sum(0.to_d, &:balance),
        invoiced: issued.select { |i| (@month..@month.end_of_month).cover?(i.issued_on) }.sum(0.to_d, &:total),
        collected: ClientInvoicePayment.joins(:client_invoice).merge(ClientInvoice.where(company_id: ActsAsTenant.current_tenant.id))
                                       .where(paid_on: @month..@month.end_of_month).sum(:amount),
        aging: aging(open), month: @month.strftime("%Y-%m") }
    end

    def clients
      issued.group_by { |i| [ i.client_id, i.client_site_id ] }.map do |(client_id, site_id), list|
        first = list.first
        { client_id:, client_site_id: site_id, name: site_id ? "#{first.bill_to_name} | #{first.client_site&.name}" : first.client.name,
          balance: list.sum(0.to_d, &:balance), invoices: list.size }
      end.sort_by { |r| -r[:balance] }
    end

    # Invoices (charge), payments and credit notes (credit) by date with a running balance, and the aging of what is open.
    def statement(client_id:, client_site_id: nil)
      list = issued.select { |i| i.client_id == client_id && i.client_site_id == client_site_id }
      rows = list.flat_map do |i|
        [ { date: i.issued_on, type: "invoice", number: i.number, charge: i.total, credit: 0 } ] +
          i.payments.map { |p| { date: p.paid_on, type: "payment", number: i.number, text: [ p.method, p.reference ].compact.join(" "), charge: 0, credit: p.amount } } +
          i.credit_notes.reject(&:void?).map { |c| { date: c.issued_on, type: "credit_note", number: c.number, text: c.reason, charge: 0, credit: c.total } }
      end.sort_by { |r| [ r[:date], r[:type] == "invoice" ? 0 : 1 ] }
      balance = 0.to_d
      rows.each { |r| r[:balance] = balance += r[:charge] - r[:credit] }
      { rows:, balance:, aging: aging(list.select { |i| i.balance > 0.005 }) }
    end

    private

    def issued = @issued ||= ClientInvoice.invoice.issued.includes(:client, :client_site, :payments, :credit_notes).to_a

    def aging(open)
      BUCKETS.map do |key, label, days|
        list = open.select { |i| days.cover?((@today - (i.due_on || i.issued_on)).to_i) }
        { key:, label:, amount: list.sum(0.to_d, &:balance), count: list.size }
      end
    end
  end
end
