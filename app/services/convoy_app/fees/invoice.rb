# Convoy App › Invoice: the bill's lines, who it is billed to, what is owed today (late fee included), how to pay it
# (the school's methods with their admin fee, the account or PayNow to pay into, the invoice number as the reference) or,
# once paid, when and how. Billing Contact only (the controller).
module ConvoyApp
  module Fees
    class Invoice < ApplicationService
      # Call inside the bill's company.
      def initialize(member:, company:, bill:)
        @member = member
        @company = company
        @bill = bill
      end

      def call
        row = Fees.rows([ @bill ]).first
        c = row.calc
        pay = c.owed <= 0.005 ? @bill.payments.reject(&:voided?).last : nil
        due = row.payable && c.owed > 0.005
        school = @bill.school
        Fees.summary(row, @company).merge(
          subtotal: @bill.subtotal, gst: { rate: @bill.gst_rate, amount: @bill.gst_amount }, late_fee: c.late, credited: c.credited, debited: c.debited, paid: c.paid,
          lines: @bill.lines.map { { child: it.child_name, description: it.description, amount: it.amount } },
          billed_to: { family: @member.household.name, contact: @member.app_account.display_name, email: receipt_to },
          request_id: request_id,
          methods: due ? Payments.options(school).map { it.json(c.owed) } : [],
          pay_to: due ? Payments.pay_to(school).merge(reference: @bill.number, amount: c.owed) : nil,
          payment: pay && { paid_on: pay.paid_on, method: pay.method, amount: pay.amount, admin_fee: pay.admin_fee, receipt_number: pay.receipt&.number, receipt_to: receipt_to }
        )
      end

      private

      # The receipt goes to the Billing Contact's email (personal first); nothing is sent until mail is built.
      def receipt_to = Parents.parent(@member.app_account)[:parent_email]

      def request_id = @bill.kind == "first" ? @bill.bus_request_id : BusRequest.where(registration_bill_id: @bill.id).pick(:id)
    end
  end
end
