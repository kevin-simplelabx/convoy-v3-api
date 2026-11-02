# Singapore banks for operator payment details (ACH bank and branch codes), platform-wide, seeded from the
# ACH Bank and Branch Code Guide. branch_rule says how the branch is found from an account number:
# pre3 (first 3 digits), pre3drop (first 3, sent without them), posb (081), sc (0 + first 2), uob (looked up by
# the first 3 digits: account_prefix rows), list (picked from the bank's branches).
class CreateBanks < ActiveRecord::Migration[8.1]
  def change
    create_table :banks do |t|
      t.string :key, null: false
      t.string :code, null: false
      t.string :name, null: false
      t.string :short_name, null: false
      t.string :branch_rule, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :banks, :key, unique: true
    add_index :banks, :code
    add_check_constraint :banks, "branch_rule IN ('pre3', 'pre3drop', 'posb', 'sc', 'uob', 'list')", name: "banks_branch_rule"

    create_table :bank_branches do |t|
      t.references :bank, null: false, foreign_key: true, index: false
      t.string :code, null: false
      t.string :name, null: false
      t.string :account_prefix
      t.timestamps
    end
    add_index :bank_branches, %i[bank_id code]
    add_index :bank_branches, %i[bank_id account_prefix], unique: true, where: "account_prefix IS NOT NULL"
  end
end
