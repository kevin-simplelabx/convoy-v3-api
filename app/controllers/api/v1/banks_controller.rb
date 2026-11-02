# Singapore banks for payment details (Managed Operators): the bank picker with branches, and the branch of an
# account number as it is typed.
module Api
  module V1
    class BanksController < BaseController
      skip_after_action :verify_authorized

      # Every bank with its branch rule; branches only for banks where the branch is picked from a list.
      def index
        banks = Bank.order(:position).includes(:branches)
        render json: { data: banks.map { |b| bank_json(b) } }
      end

      # GET /banks/:id/branch?account_number=&branch_code= → { code, name, send, note, error, rule }
      def branch
        bank = Bank.includes(:branches).find(params[:id])
        result = Banks::BranchFor.call(bank:, account_number: params[:account_number], branch_code: params[:branch_code])
        render json: { data: result.merge(rule: bank.rule_text) }
      end

      private

      def bank_json(bank)
        { id: bank.id, key: bank.key, code: bank.code, name: bank.name, short_name: bank.short_name, label: bank.label,
          branch_rule: bank.branch_rule, rule_text: bank.rule_text, pick_branch: bank.pick_branch?,
          enter_branch: bank.branch_rule == "list" && bank.branches.empty?,
          branches: bank.branch_rule == "list" ? bank.branches.map { |br| { code: br.code, name: br.name } } : [] }
      end
    end
  end
end
