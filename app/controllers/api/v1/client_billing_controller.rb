# Finance > Client Invoices > Billing Details of a client: Billing Name (legal name on invoices, blank = the client's
# name), UEN, billing address, the people who get invoices, terms
# (days), default PO and the late-cancellation cut-off (hours). Sites billed as their own entity are edited on the site.
module Api
  module V1
    class ClientBillingController < BaseController
      def show
        authorize :finance, :show?
        render_billing
      end

      # PATCH /finance/billing/:client_id { billing: { billing_name, uen, billing_address, payment_terms_days, default_po, late_cancel_hours,
      #                                                 billing_contacts: [{ name, email, send_as, attention }] } }
      def update
        authorize :finance, :update?
        attrs = params.expect(billing: [ :billing_name, :uen, :billing_address, :payment_terms_days, :default_po, :late_cancel_hours,
                                         { billing_contacts: [ %i[name email send_as attention] ] } ])
        Client.transaction do
          client.update!(attrs.except(:billing_contacts))
          ClientBillingContact.replace!(client, attrs[:billing_contacts]) if attrs.key?(:billing_contacts)
        end
        render_billing
      end

      private

      def client = @client ||= Client.kept.find(params[:client_id])

      def render_billing
        c = client.reload
        render json: { data: { client_id: c.id, name: c.name, kind: c.kind, billing_name: c.billing_name, bill_name: c.bill_name, uen: c.uen, billing_address: c.billing_address,
                               payment_terms_days: c.payment_terms_days, terms_days: c.terms_days, default_po: c.default_po,
                               late_cancel_hours: c.late_cancel_hours,
                               billing_contacts: ClientBillingContactBlueprint.render_as_hash(c.billing_contacts) } }
      end
    end
  end
end
