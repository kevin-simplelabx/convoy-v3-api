# Managed Operators: the bank picked from the list (DBS and POSB share ACH code 7171, so the bank row is kept, with
# bank_code copied from it for payment files) and, for external operators, the usual hire cost per trip and per day.
class AddBankAndCostsToOperators < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :operators, :bank, index: { algorithm: :concurrently }
    add_foreign_key :operators, :banks, validate: false
    add_column :operators, :cost_per_trip, :decimal, precision: 12, scale: 2
    add_column :operators, :cost_per_day, :decimal, precision: 12, scale: 2
  end
end
