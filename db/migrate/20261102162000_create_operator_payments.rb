# Finance > Operator Payments. What the company owes operators comes from the Scheduler (each run on an operator's bus at
# its operator cost, replacements we arranged as deductions) plus manual items (operator_pay_items). Finance can set a
# run's cost (operator_cost_overrides, so runs that ran are not rewritten). Approved items go into a batch by pay date
# (or an ad hoc batch for one operator): one payment notice (PN) and one bank file line per operator, then payments.
# Batch lines keep the item's ref (run:<id>:<date>, replacement:<id>, item:<id>) so an item is paid once.
class CreateOperatorPayments < ActiveRecord::Migration[8.1]
  def change
    create_table :operator_cost_overrides do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.references :set_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :operator_cost_overrides, %i[occurrence_id occurrence_date], unique: true
    add_index :operator_cost_overrides, :company_id

    create_table :operator_pay_items do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :operator, null: false, foreign_key: true
      t.string :description, null: false
      t.date :item_on, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :operator_pay_items, :company_id

    create_table :operator_pay_batches do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :number, null: false
      t.string :kind, null: false, default: "batch"
      t.date :pay_date, null: false
      t.string :transfer_type
      t.datetime :bank_file_at
      t.references :bank_file_by, foreign_key: { to_table: :users }
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :operator_pay_batches, %i[company_id pay_date]
    add_check_constraint :operator_pay_batches, "kind IN ('batch', 'adhoc')", name: "operator_pay_batches_kind"

    create_table :operator_pay_batch_operators do |t|
      t.references :operator_pay_batch, null: false, foreign_key: true, index: false
      t.references :operator, null: false, foreign_key: true
      t.string :notice_number
      t.string :pay_method
      t.string :pay_to
      t.timestamps
    end
    add_index :operator_pay_batch_operators, %i[operator_pay_batch_id operator_id], unique: true, name: "index_operator_pay_batch_operators_unique"

    create_table :operator_pay_batch_lines do |t|
      t.references :operator_pay_batch_operator, null: false, foreign_key: true
      t.string :ref, null: false
      t.string :source, null: false
      t.string :description, null: false
      t.string :details
      t.date :item_on
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.timestamps
    end
    add_index :operator_pay_batch_lines, :ref, unique: true

    create_table :operator_pay_payments do |t|
      t.references :operator_pay_batch_operator, null: false, foreign_key: true
      t.date :paid_on, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :method, null: false
      t.string :reference
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
