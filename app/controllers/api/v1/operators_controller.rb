# Transport operators: managed (Managed Operators) and external (companies external vehicles are hired from).
# The list adds the Routes column (School Bus routes their buses run) and the number of buses.
module Api
  module V1
    class OperatorsController < BaseController
      def index
        authorize Operator
        scope = policy_scope(Operator).kept.includes(bank: :branches).ransack(ransack_params).result.order(:name)
        render_page scope, OperatorBlueprint, view: :list, routes: Operators::RouteCounts.call,
                                              vehicles: Vehicle.kept.where.not(operator_id: nil).group(:operator_id).count
      end

      def show
        render_data authorize(Operator.kept.find(params[:id])), OperatorBlueprint, view: :detail
      end

      def create
        operator = authorize Operator.new(operator_params)
        operator.save!
        render_data operator, OperatorBlueprint, view: :detail, status: :created
      end

      def update
        operator = authorize Operator.kept.find(params[:id])
        operator.update!(operator_params)
        render_data operator, OperatorBlueprint, view: :detail
      end

      def destroy
        operator = authorize Operator.kept.find(params[:id])
        if operator.vehicles.kept.exists?
          n = operator.vehicles.kept.count
          return render_error(:unprocessable_content, "Remove the #{n} #{'vehicle'.pluralize(n)} of #{operator.name} first")
        end

        operator.discard!
        head :no_content
      end

      private

      def operator_params
        params.expect(operator: %i[name kind uen contact_name phone email payment_method paynow_uen bank_id
                                   branch_code account_number account_name valid_until cost_per_trip cost_per_day])
      end
    end
  end
end
