# School Bus › Year Setup › Payment Methods of a school: how parents may pay in the Convoy App, admin fees, and the
# account that receives the money (the company's from Finance Settings, or the school's own).
module Api
  module V1
    class SchoolPaymentMethodsController < BaseController
      def show
        school = authorize find_school, :show?
        render json: { data: payload(school) }
      end

      # PUT /schools/:school_id/payment_methods { bank: { on, fee_kind, fee }, paynow: {…}, card: {…}, own_account, bank_id,
      #   account_number, account_name, paynow_id }
      def update
        school = authorize find_school, :money_setup?
        Policies::SavePaymentMethods.call(school, method_params, user: current_user)
        render json: { data: payload(school.reload) }
      end

      private

      def find_school = policy_scope(School).includes(payment_method: %i[bank updated_by]).find(params[:school_id])

      def payload(school)
        m = school.payment_method
        company = FinanceSetting.current
        methods = SchoolPaymentMethod::METHODS.to_h do |k, label|
          [ k, { label:, on: m ? m[:"#{k}_on"] : k != "card", fee_kind: m ? m[:"#{k}_fee_kind"] : "none", fee: m&.[](:"#{k}_fee") } ]
        end
        { saved: m.present?, **methods, own_account: m&.own_account || false, account_bank: m&.bank&.slice(:id, :name, :code), account_number: m&.account_number,
          account_name: m&.account_name, paynow_id: m&.paynow_id, updated_by: m&.updated_by&.name, updated_at: m&.updated_at,
          company_account: { bank: company.bank&.slice(:id, :name, :code), account_number: company.account_number, account_name: company.account_name,
                             paynow: company.paynow } }
      end

      def method_params
        cast = ->(v) { ActiveModel::Type::Boolean.new.cast(v) || false }
        p = params.permit(:own_account, :bank_id, :account_number, :account_name, :paynow_id, bank: %i[on fee_kind fee], paynow: %i[on fee_kind fee],
                                                                                                  card: %i[on fee_kind fee]).to_h.deep_symbolize_keys
        p[:own_account] = cast.(p[:own_account])
        %i[bank paynow card].each { |k| p[k] = (p[k] || {}).merge(on: cast.((p[k] || {})[:on])) }
        p
      end
    end
  end
end
