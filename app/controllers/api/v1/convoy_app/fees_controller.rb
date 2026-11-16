# Convoy App › Fees (Billing Contact only): the bills and payment history, an invoice with how to pay it, and Pay (simulated).
module Api
  module V1
    module ConvoyApp
      class FeesController < SchoolBaseController
        before_action :require_billing!

        # GET /app/fees → { family, outstanding { total, count, pay_first_id, items }, invoices, payments }
        def index
          render json: { data: ::ConvoyApp::Fees::Overview.call(member: current_member) }
        end

        # GET /app/fees/invoices/:id → invoice (lines, billed_to, methods with admin fee, pay_to, or the payment once paid)
        def show
          render json: { data: invoice(params[:id]) }
        end

        # POST /app/fees/invoices/:id/pay { method: bank|paynow|card } → invoice (paid; the request is Active for a first invoice)
        def pay
          key = params.require(:method)
          ::ConvoyApp::Fees.with_bill(household, params[:id]) { |_company, bill| ::ConvoyApp::Fees::Pay.call(member: current_member, bill:, method: key) }
          render json: { data: invoice(params[:id]) }
        end

        private

        def require_billing!
          render_error(:forbidden, "Only the Billing Contact of your Family sees Fees", code: "billing_only") unless billing?
        end

        def invoice(id)
          ::ConvoyApp::Fees.with_bill(household, id) { |company, bill| ::ConvoyApp::Fees::Invoice.call(member: current_member, company:, bill:) }
        end
      end
    end
  end
end
