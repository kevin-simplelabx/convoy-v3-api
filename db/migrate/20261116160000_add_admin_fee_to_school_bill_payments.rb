# The admin fee a card / PayNow method passes on, recorded beside the payment (the bill is cleared by `amount`; the fee is
# the provider's surcharge, not revenue of the bill). Convoy App payments only; console payments keep 0.
class AddAdminFeeToSchoolBillPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :school_bill_payments, :admin_fee, :decimal, precision: 12, scale: 2, default: 0, null: false
  end
end
