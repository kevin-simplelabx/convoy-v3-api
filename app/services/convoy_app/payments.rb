# Convoy App › paying a School Bus bill or CCA rides: the ways a school lets parents pay (Payment & Refund Policy ›
# Payment Methods, read inside the school's company), each with its admin fee, and where the money goes. The money itself is
# "collected" by Payments::Simulator until a provider is chosen (decision 2026-11-04: payment simulated as paid).
module ConvoyApp
  module Payments
    ICONS = { "bank" => "account_balance", "paynow" => "qr_code_2", "card" => "credit_card" }.freeze

    # One way to pay: key bank | paynow | card; fee_kind none | fixed (S$) | pct (a percentage, as the HTML's +x%).
    Option = Data.define(:key, :label, :icon, :fee_kind, :fee) do
      def fee_for(amount)
        case fee_kind
        when "fixed" then fee.round(2)
        when "pct" then (amount * fee / 100).round(2)
        else 0.to_d
        end
      end

      def fee_text
        case fee_kind
        when "fixed" then "+S$#{format('%.2f', fee)} admin fee"
        when "pct" then "+#{fee.to_s('F').sub(/\.0\z/, '')}% admin fee"
        else "No fee"
        end
      end

      # amount: what is owed now; the fee and the total the parent is charged.
      def json(amount = nil)
        base = { key:, label:, icon:, fee_kind:, fee:, fee_text: }
        return base unless amount

        base.merge(admin_fee: fee_for(amount), total: amount + fee_for(amount))
      end
    end

    module_function

    # The school's ways to pay that are on (no saved row = Bank Transfer and PayNow, no fee). Call inside the school's company.
    def options(school)
      row = school.payment_method
      SchoolPaymentMethod::METHODS.filter_map do |key, label|
        next unless row ? row[:"#{key}_on"] : key != "card"

        kind = row ? row[:"#{key}_fee_kind"] : "none"
        Option.new(key:, label:, icon: ICONS[key], fee_kind: kind, fee: kind == "none" ? 0.to_d : row[:"#{key}_fee"].to_d)
      end
    end

    # Where a school's payments go: its own account, else the company's (Finance Settings › Payment Details).
    def pay_to(school)
      row = school.payment_method
      own = row&.own_account
      src = own ? row : FinanceSetting.current
      bank = src.bank
      { own:, bank: bank&.name, bank_code: bank&.code, account_name: src.account_name, account_number: src.account_number,
        paynow: own ? row.paynow_id : src.paynow }
    end
  end
end
