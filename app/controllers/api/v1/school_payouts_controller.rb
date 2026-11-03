# School Bus › School Finance › Operator Payments: a school's month of operator pay runs (routes, route pay, lines, status,
# totals), and the pay run of one operator: lines (with files), invoice number, Send to Finance, Recall, Send Back,
# Approve, Reopen, Pay, and the Payment Voucher to print.
module Api
  module V1
    class SchoolPayoutsController < BaseController
      # GET /schools/:school_id/payouts?month=YYYY-MM
      def index
        authorize :finance, :index?
        render json: { data: SchoolPay::Board.call(find_school, month, user: current_user) }
      end

      # POST /schools/:school_id/payouts/:operator_id/lines { kind, adj_on, route, amount, reason, paired_operator_id, files: [] }
      def add_line
        authorize :finance, :update?
        acts.add_line(params.permit(:kind, :adj_on, :route, :amount, :reason, :paired_operator_id), files: Array(params[:files]).compact)
        board(status: :created)
      end

      # DELETE /schools/:school_id/payouts/:operator_id/lines/:line_id?month=
      def remove_line
        authorize :finance, :update?
        acts.remove_line(params[:line_id])
        board
      end

      # PATCH /schools/:school_id/payouts/:operator_id { month, invoice_number }
      def update
        authorize :finance, :update?
        acts.invoice_number(params[:invoice_number])
        board
      end

      # POST /schools/:school_id/payouts/:operator_id/(send|recall|send_back|approve|reopen) { month }
      %i[send_to_finance recall send_back approve reopen].each do |name|
        define_method(name) do
          authorize :finance, :update?
          acts.public_send(name)
          board
        end
      end

      # POST /schools/:school_id/payouts/:operator_id/payments { month, paid_on, amount, method, reference }
      def pay
        authorize :finance, :create?
        acts.pay(params.permit(:paid_on, :amount, :method, :reference))
        board(status: :created)
      end

      # GET /school_payouts/:id/voucher — the Payment Voucher to print (brand: GET /finance/documents/brand).
      def voucher
        authorize :finance, :show?
        p = SchoolPayout.where(school: policy_scope(School)).includes(:school, :operator, :payments, :approved_by, :prepared_by, :adjustments).find(params[:id])
        render json: { data: SchoolPay.voucher(p) }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])
      def acts = @acts ||= SchoolPay::Actions.new(find_school, month, Operator.find(params[:operator_id]), user: current_user)

      def month
        Date.strptime(params[:month].to_s, "%Y-%m")
      rescue Date::Error
        Date.current.beginning_of_month
      end

      def board(status: :ok) = render(json: { data: SchoolPay::Board.call(find_school, month, user: current_user) }, status:)
    end
  end
end
