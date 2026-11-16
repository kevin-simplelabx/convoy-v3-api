# Convoy App › Fees: Outstanding card (what is due, "Pay with PayNow" goes to the earliest due bill), the Invoices tab and the
# Payments tab (history, newest first). Every company the Family deals with is read inside that company.
module ConvoyApp
  module Fees
    class Overview < ApplicationService
      def initialize(member:)
        @household = member.household
      end

      def call
        invoices = []
        payments = []
        due = []
        Parents.companies(@household).each do |company|
          Parents.within(company) do
            rows = Fees.rows(Fees.load(Fees.scope(@household)))
            invoices.concat(rows.map { [ it.bill.issued_on, it.bill.id, Fees.summary(it, company) ] })
            due.concat(rows.select { Fees.outstanding?(it) }.map { [ it.bill.due_on || it.bill.issued_on, it.bill.id, it.calc.owed, Fees.summary(it, company) ] })
            payments.concat(rows.flat_map { |r| r.bill.payments.reject(&:voided?).map { |p| payment(p, r.bill, company) } })
          end
        end
        due.sort_by! { it.first(2) }
        { family: { name: @household.name },
          outstanding: { total: due.sum(0.to_d) { it[2] }, count: due.size, pay_first_id: due.first&.dig(3, :id),
                         items: due.map { it[3].slice(:id, :number, :period, :due_on, :owed, :school, :company) } },
          invoices: invoices.sort_by { [ it[0], it[1] ] }.reverse.map(&:last),
          payments: payments.sort_by { [ it[:paid_on], it[:id] ] }.reverse }
      end

      private

      def payment(pay, bill, company)
        { id: pay.id, amount: pay.amount, admin_fee: pay.admin_fee, method: pay.method, paid_on: pay.paid_on, bill_id: bill.id, number: bill.number,
          period: bill.period_label, receipt_number: pay.receipt&.number, company: Parents.company_json(company) }
      end
    end
  end
end
