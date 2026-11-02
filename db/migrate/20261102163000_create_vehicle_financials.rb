# Finance > Vehicle Financials: how an own vehicle was bought (paid in full, or a loan with its terms; the lender's
# instalment schedule file, read by Claude) and the instalments paid. Manual revenue / cost entries (once or every
# month until stopped) and cost spikes marked as checked feed the vehicle's profit and loss.
class CreateVehicleFinancials < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicle_financials do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :vehicle, null: false, foreign_key: true, index: { unique: true }
      t.string :funding, null: false, default: "loan"
      t.decimal :purchase_price, precision: 12, scale: 2
      t.decimal :down_payment, precision: 12, scale: 2
      t.date :bought_on
      t.string :lender
      t.string :account_number
      t.decimal :loan_amount, precision: 12, scale: 2
      t.decimal :rate, precision: 6, scale: 3
      t.integer :tenure_months
      t.decimal :term_charge, precision: 12, scale: 2
      t.decimal :first_instalment, precision: 12, scale: 2
      t.decimal :monthly_instalment, precision: 12, scale: 2
      t.decimal :last_instalment, precision: 12, scale: 2
      t.date :first_due_on
      t.string :schedule_file
      t.references :document_read, foreign_key: true
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :vehicle_financials, :company_id
    add_check_constraint :vehicle_financials, "funding IN ('loan', 'cash')", name: "vehicle_financials_funding"

    create_table :vehicle_loan_payments do |t|
      t.references :vehicle_financial, null: false, foreign_key: true, index: false
      t.integer :instalment_no, null: false
      t.date :paid_on, null: false
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :vehicle_loan_payments, %i[vehicle_financial_id instalment_no], unique: true, name: "index_vehicle_loan_payments_unique"

    create_table :vehicle_finance_entries do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :vehicle, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :category, null: false
      t.date :entry_on, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.boolean :repeats_monthly, null: false, default: false
      t.date :repeat_until
      t.text :note
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :vehicle_finance_entries, %i[company_id entry_on]
    add_check_constraint :vehicle_finance_entries, "kind IN ('revenue', 'cost')", name: "vehicle_finance_entries_kind"

    create_table :vehicle_cost_spike_acks do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :vehicle, null: false, foreign_key: true, index: false
      t.string :category, null: false
      t.date :month, null: false
      t.references :checked_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :vehicle_cost_spike_acks, %i[vehicle_id category month], unique: true, name: "index_vehicle_cost_spike_acks_unique"
  end
end
