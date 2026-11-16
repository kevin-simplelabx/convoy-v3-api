# Family bills just issued (SchoolBills::Issue): the Billing Contact of the Family is told (bills are theirs only). Bills
# the school pays, and bills of families not linked to a Family in the app, are left out. Tap opens the invoice.
module ConvoyApp
  module Alerts
    class Bills < ApplicationService
      def initialize(bills)
        @bills = Array(bills).select { it.payer == "family" && it.family_id }
      end

      def call
        return 0 if @bills.empty?

        households = Family.where(id: @bills.map(&:family_id)).pluck(:id, :household_id).to_h.compact
        billing = Alerts.adults_of(households.values.uniq, billing: true)
        Alerts.write(@bills.flat_map do |bill|
          ids = billing[households[bill.family_id]] || []
          what = [ bill.period_label, Parents::Present.money(bill.total), bill.due_on && "due #{bill.due_on.strftime('%-d %b')}" ].compact.join(" · ")
          Alerts.rows_for(ids, kind: "bill_issued", title: "Invoice #{bill.number} issued", body: "#{what}.", company_id: bill.company_id,
                               target: "fee_invoice", target_id: bill.id, dedupe_key: "bill:#{bill.id}")
        end)
      end
    end
  end
end
