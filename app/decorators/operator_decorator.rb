class OperatorDecorator < ApplicationDecorator
  # Pays By column and payment notices: { method: "PayNow UEN" | "Bank Transfer" | "Not set", to:, warn: }.
  def pays_by
    bank_text = bank && account_number && [ "#{bank.short_name} #{account_number}", account_name ].compact_blank.join(" | ")
    if external? && payment_method.nil?
      paynow_uen ? { method: "PayNow UEN", to: paynow_uen, warn: false } : { method: "Not set", to: "Add PayNow / UEN in External Vehicles", warn: true }
    elsif bank?
      { method: "Bank Transfer", to: bank_text || "Bank details missing", warn: bank_text.nil? }
    elsif paynow_uen then { method: "PayNow UEN", to: paynow_uen, warn: false }
    elsif bank_text then { method: "Bank Transfer", to: bank_text, warn: false }
    else { method: "Not set", to: "Add payment details in Managed Operators", warn: true }
    end
  end

  def branch_name = bank && branch_code && bank.branches.find { |b| b.code == branch_code }&.name
end
