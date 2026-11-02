# Finance > Operator Payments: Payment Requests (by operator), cost of a run, manual items, Approve and Set Pay Date,
# Ad Hoc Payment, Batches (pay date, cancel, payments, Mark All Paid, bank file and payment notices).
module Api
  module V1
    class OperatorPaymentsController < BaseController
      BATCH_INCLUDES = { batch_operators: [ { operator: { bank: :branches } }, :lines, :payments ] }.freeze

      # GET /finance/operator_pay/requests
      def requests
        authorize :finance, :index?
        items = OperatorPay::Due.call
        groups = items.group_by(&:operator).sort_by { |op, _| op.name }.map do |op, list|
          { operator: { id: op.id, name: op.name }, pays_by: op.decorate.pays_by,
            to_approve: list.select(&:ready).sum(0.to_d) { |i| i.amount.to_d }, not_ready: list.reject(&:ready).size,
            items: list.map { |i| i.to_h.except(:operator) } }
        end
        render json: { data: groups, meta: kpis(items) }
      end

      # PUT /finance/operator_pay/costs { ref: "run:<id>:<date>", amount }
      def set_cost
        authorize :finance, :update?
        _, id, date = params.require(:ref).to_s.split(":")
        occ = TripOccurrence.find_by!(id:, date:)
        OperatorCostOverride.find_or_initialize_by(occurrence_id: occ.id, occurrence_date: occ.date).update!(amount: params.require(:amount), set_by: current_user)
        head :no_content
      end

      # POST /finance/operator_pay/items { operator_id, description, item_on, amount, sign: pay | deduct }
      def create_item
        authorize :finance, :create?
        amount = params[:amount].to_d.abs
        raise ApplicationService::Error, "Enter the amount" unless amount.positive?

        OperatorPayItem.create!(operator: Operator.kept.find(params.require(:operator_id)), description: params[:description], item_on: params[:item_on],
                                amount: params[:sign] == "deduct" ? -amount : amount, created_by: current_user)
        head :created
      end

      def destroy_item
        authorize :finance, :destroy?
        item = OperatorPayItem.find(params[:id])
        raise ApplicationService::Error, "This item is in a batch. Cancel the batch first" if OperatorPayBatchLine.exists?(ref: "item:#{item.id}")

        item.destroy!
        head :no_content
      end

      # POST /finance/operator_pay/approve { refs: [], pay_date } or { refs: [], batch_id }
      def approve
        authorize :finance, :update?
        render_batch service.approve!(refs: params[:refs], pay_date: params[:pay_date], batch_id: params[:batch_id]), status: :created
      end

      # POST /finance/operator_pay/ad_hoc { operator_id, pay_date, refs: [], extra: { description, amount } }
      def ad_hoc
        authorize :finance, :update?
        extra = params[:extra]&.permit(:description, :amount)&.to_h&.symbolize_keys
        render_batch service.ad_hoc!(operator: Operator.kept.find(params.require(:operator_id)), pay_date: params[:pay_date], refs: params[:refs], extra:),
                     status: :created
      end

      # GET /finance/operator_pay/batches
      def batches
        authorize :finance, :index?
        list = OperatorPayBatch.includes(BATCH_INCLUDES).order(pay_date: :desc, id: :desc)
        render json: { data: OperatorPayBatchBlueprint.render_as_hash(list) }
      end

      def batch
        authorize :finance, :show?
        render_batch find_batch
      end

      # PATCH /finance/operator_pay/batches/:id { pay_date, merge: true }
      def update_batch
        authorize :finance, :update?
        render_batch service.change_date!(find_batch, params.require(:pay_date), merge: ActiveModel::Type::Boolean.new.cast(params[:merge]))
      end

      def cancel_batch
        authorize :finance, :update?
        service.cancel!(find_batch)
        head :no_content
      end

      # POST /finance/operator_pay/batches/:id/payments { batch_operator_id, paid_on, amount, method, reference }
      def pay
        authorize :finance, :update?
        bo = find_batch.batch_operators.find(params.require(:batch_operator_id))
        service.pay!(bo, paid_on: params[:paid_on], amount: params[:amount], method: params[:method], reference: params[:reference])
        render_batch find_batch
      end

      def mark_paid
        authorize :finance, :update?
        service.mark_all_paid!(find_batch)
        render_batch find_batch
      end

      # POST /finance/operator_pay/batches/:id/bank_file { transfer_type: FAST | GIRO } → the batch + the CSV
      def bank_file
        authorize :finance, :update?
        batch = service.bank_file!(find_batch, transfer_type: params.require(:transfer_type))
        batch = OperatorPayBatch.includes(BATCH_INCLUDES).find(batch.id)
        render json: { data: OperatorPayBatchBlueprint.render_as_hash(batch, view: :detail).merge(csv: OperatorPay::Batches.csv(batch),
                                                                                                    filename: "#{batch.number}.csv") }
      end

      # GET /finance/operator_pay/batches/:id/bank_file.csv — Download Again
      def download_bank_file
        authorize :finance, :show?
        batch = find_batch
        raise ApplicationService::Error, "Make the bank file first" unless batch.bank_file_at

        send_data OperatorPay::Batches.csv(batch), filename: "#{batch.number}.csv", type: "text/csv"
      end

      private

      def service = OperatorPay::Batches.new(user: current_user)

      def find_batch = @batch ||= OperatorPayBatch.includes(BATCH_INCLUDES).find(params[:id])

      def render_batch(batch, status: :ok)
        render_data OperatorPayBatch.includes(BATCH_INCLUDES).find(batch.id), OperatorPayBatchBlueprint, view: :detail, status:
      end

      def kpis(items)
        ready = items.select(&:ready)
        unpaid = OperatorPayBatch.includes(batch_operators: %i[lines payments]).to_a.select { |b| b.status != "paid" }
        nxt = unpaid.min_by(&:pay_date)
        approver = FinanceApprover.where(company_id: ActsAsTenant.current_tenant.id, can_approve: true)
        { waiting: ready.sum(0.to_d) { |i| i.amount.to_d }, waiting_items: ready.size, waiting_operators: ready.map(&:operator).uniq.size,
          approved_unpaid: unpaid.sum(0.to_d) { |b| b.total - b.paid }, approved_batches: unpaid.size,
          next_pay: nxt && { date: nxt.pay_date, number: nxt.number, amount: nxt.total - nxt.paid, overdue: nxt.pay_date < Date.current },
          can_approve: approver.none? || approver.exists?(user_id: current_user.id) }
      end
    end
  end
end
