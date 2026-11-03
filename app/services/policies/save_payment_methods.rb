# Payment Methods › Save: at least one way to pay; admin fees above 0 (a % up to 10); Bank Transfer needs an account
# and PayNow a UEN or mobile — the school's own, or the company's from Finance Settings › Payment Details.
module Policies
  class SavePaymentMethods < ApplicationService
    def initialize(school, params, user:)
      @school = school
      @p = params
      @user = user
    end

    def call
      on = SchoolPaymentMethod::METHODS.keys.select { @p.dig(it.to_sym, :on) }
      raise Error, "Turn on at least one way to pay" if on.empty?

      on.each do |k|
        m = @p[k.to_sym]
        label = SchoolPaymentMethod::METHODS[k]
        next if m[:fee_kind].blank? || m[:fee_kind] == "none"
        raise Error, "Enter the admin fee for #{label}" unless m[:fee].to_d.positive?
        raise Error, "The admin fee for #{label} looks too high: use a percentage up to 10" if m[:fee_kind] == "pct" && m[:fee].to_d > 10
      end
      own = @p[:own_account]
      account = own ? @p[:account_number].to_s.gsub(/\D/, "") : FinanceSetting.current.account_number.to_s
      bank = own ? @p[:bank_id].presence : FinanceSetting.current.bank_id
      paynow = (own ? @p[:paynow_id] : FinanceSetting.current.paynow).to_s.strip.upcase
      if on.include?("bank") && (bank.blank? || account.blank?)
        raise Error, own ? "Pick the bank and enter the account for Bank Transfer" : "Bank Transfer needs the company's bank account: add it in Finance Settings, Payment Details, or use this school's own account"
      end
      if on.include?("paynow") && paynow.empty?
        raise Error, own ? "Enter the PayNow UEN or mobile for this school" : "PayNow needs the company's PayNow UEN: add it in Finance Settings, Payment Details, or use this school's own account"
      end

      row = @school.payment_method || @school.build_payment_method
      attrs = SchoolPaymentMethod::METHODS.keys.each_with_object({}) do |k, h|
        m = @p[k.to_sym] || {}
        h[:"#{k}_on"] = on.include?(k)
        h[:"#{k}_fee_kind"] = m[:fee_kind].presence || "none"
        h[:"#{k}_fee"] = m[:fee_kind].presence.in?([ nil, "none" ]) ? nil : m[:fee]
      end
      row.update!(attrs.merge(own_account: !!own, bank_id: own ? @p[:bank_id].presence : nil, account_number: own ? account.presence : nil,
                              account_name: own ? @p[:account_name].presence : nil, paynow_id: own ? paynow.presence : nil, updated_by: @user))
      row
    end
  end
end
