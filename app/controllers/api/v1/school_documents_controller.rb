# School Bus › School Finance › Documents: a school's invoices, credit / debit notes and receipts (filter by type, payer,
# search), one document with what to print, Void a receipt, and a payer's Statement of Account.
module Api
  module V1
    class SchoolDocumentsController < BaseController
      # GET /schools/:school_id/documents?type=inv|cn|dn|rcp&payer=family:<id>|school&q=
      def index
        authorize :finance, :index?
        out = SchoolBills::Documents.call([ find_school ], type: params[:type], payer: params[:payer], q: params[:q])
        render json: { data: out[:rows], meta: { count: out[:count], shown: out[:rows].size, counts: out[:counts], payers: out[:payers],
                                                 types: SchoolBills::Documents::TYPES } }
      end

      # GET /schools/:school_id/statement?payer=family:<id>|school
      def statement
        authorize :finance, :index?
        render json: { data: SchoolBills::Statement.call(find_school, params.require(:payer)) }
      end

      # GET /school_documents/:id — a credit note, debit note or receipt to print (the brand: GET /finance/documents/brand).
      def show
        authorize :finance, :show?
        render json: { data: view(find) }
      end

      # POST /school_documents/:id/void { reason }
      def void
        authorize :finance, :update?
        SchoolBills::VoidReceipt.call(find, reason: params[:reason], user: current_user)
        render json: { data: view(find) }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def find
        SchoolDocument.where(school: policy_scope(School)).includes(:school_bill, :applied_bill, :created_by, :voided_by, payments: :school_bill).find(params[:id])
      end

      def view(d)
        bill = d.school_bill
        base = { id: d.id, type: d.doc_type, title: d.type_name == "Receipt" ? "Official Receipt" : d.type_name, number: d.number, date: d.issued_on,
                 school_id: d.school_id, to: d.bill_to, to_code: bill&.bill_to_code, status: d.status_text, total: d.total, reason: d.reason,
                 by: d.created_by&.name, void: d.voided? ? { at: d.voided_at, reason: d.void_reason, by: d.voided_by&.name } : nil }
        return base.merge(method: d.method, reference: d.reference, can_void: !d.voided?, applied: d.payments.map { { bill_id: it.school_bill_id, number: it.school_bill.number, amount: it.amount } }) if d.receipt?

        use = case d.credit_use
        when "reduce" then "Taken off #{bill&.number}"
        when "refund" then "Refunded on #{d.refund_on&.strftime('%d/%m/%Y')} by #{d.method}#{", ref #{d.reference}" if d.reference}"
        when "carry" then d.applied_bill ? "Taken off #{d.applied_bill.number}" : "Will be taken off the next bill"
        end
        base.merge(bill: bill && { id: bill.id, number: bill.number }, lines: [ { description: d.description, amount: d.subtotal } ], subtotal: d.subtotal,
                   gst: d.gst_rate.positive? ? { rate: d.gst_rate, amount: d.gst_amount } : nil, credit_use: d.credit_use, use_text: use,
                   refund: d.credit_use == "refund" ? { on: d.refund_on, method: d.method, reference: d.reference } : nil)
      end
    end
  end
end
