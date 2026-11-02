# Finance > Documents: every client invoice, credit note and operator payment notice, with the data to print one.
module Api
  module V1
    class FinanceDocumentsController < BaseController
      # GET /finance/documents?type=invoice|credit_note|payment_notice&q=
      def index
        authorize :finance, :index?
        out = Finance::Documents.call(type: params[:type], q: params[:q])
        render json: { data: out[:rows], meta: { count: out[:count], shown: out[:rows].size, counts: out[:counts], types: Finance::Documents::TYPES } }
      end

      # GET /finance/documents/payment_notices/:id — a payment notice to print (the operator's lines and payments).
      def payment_notice
        authorize :finance, :show?
        bo = OperatorPayBatchOperator.includes(:operator, :lines, :payments, :operator_pay_batch).find(params[:id])
        raise ActiveRecord::RecordNotFound unless bo.operator_pay_batch.company_id == ActsAsTenant.current_tenant.id

        render json: { data: { number: bo.notice_number, pay_date: bo.operator_pay_batch.pay_date, batch: bo.operator_pay_batch.number,
                               operator: { id: bo.operator.id, name: bo.operator.name, uen: bo.operator.uen, email: bo.operator.email },
                               pays_by: { method: bo.pay_method, to: bo.pay_to }, total: bo.total, paid: bo.paid, left: bo.left,
                               lines: bo.lines.map { |l| l.slice(:description, :details, :item_on, :amount) },
                               payments: bo.payments.map { |p| p.slice(:paid_on, :amount, :method, :reference) },
                               brand: brand } }
      end

      # GET /finance/documents/brand — the header and footer every printed document shows.
      def brand_info
        authorize :finance, :index?
        render json: { data: brand }
      end

      private

      def brand
        s = FinanceSetting.current
        company = s.company.decorate
        { name: s.brand_name || company.name, uen: s.brand_uen, gst_reg_no: (s.gst_reg_no if s.gst_on), address: s.brand_address,
          phone: s.brand_phone, email: s.brand_email, note: s.brand_note, logo: company.logo_info,
          payment: { bank: s.bank&.name, account_number: s.account_number, account_name: s.account_name, paynow: s.paynow, note: s.payment_note } }
      end
    end
  end
end
