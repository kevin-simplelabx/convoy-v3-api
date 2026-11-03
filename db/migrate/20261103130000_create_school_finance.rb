# School Bus › School Finance: bills for every billing period (drafted by Convoy, issued by Finance) to a family or to the
# school (its Managed Client), with their payments, waivers, and the documents raised on them: credit notes (off the bill,
# refunded, or carried to the next bill), debit notes and receipts (a receipt pays one or more bills; void only).
class CreateSchoolFinance < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    create_table :school_documents do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.string :doc_type, null: false
      t.string :number, null: false
      t.date :issued_on, null: false
      t.references :school_bill, foreign_key: { on_delete: :cascade }
      t.references :family, foreign_key: { on_delete: :nullify }, index: false
      t.string :payer, null: false, default: "family"
      t.string :bill_to
      t.string :description
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 0
      t.decimal :gst_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false
      t.text :reason
      t.string :credit_use
      t.date :refund_on
      t.string :method
      t.string :reference
      t.bigint :applied_bill_id
      t.timestamptz :voided_at
      t.text :void_reason
      t.references :voided_by, foreign_key: { to_table: :users }, index: false
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :school_documents, %i[company_id number], unique: true
    add_index :school_documents, %i[school_id doc_type issued_on]
    add_index :school_documents, :applied_bill_id, where: "applied_bill_id IS NOT NULL"

    create_table :school_bill_payments do |t|
      t.references :school_bill, null: false, foreign_key: { on_delete: :cascade }
      t.references :receipt, foreign_key: { to_table: :school_documents, on_delete: :nullify }
      t.date :paid_on, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :method
      t.string :reference
      t.string :source, null: false, default: "console"
      t.references :recorded_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :voided_at
      t.timestamps
    end

    create_table :school_bill_waivers do |t|
      t.references :school_bill, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false, default: "late"
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :reason, null: false
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    change_column_null :school_bills, :number, true
    add_column :school_bills, :payer, :string, null: false, default: "family"
    add_column :school_bills, :bill_to_email, :string
    add_column :school_bills, :bill_to_code, :string
    add_column :school_bills, :period_index, :integer
    add_column :school_bills, :billing_month, :date
    add_column :school_bills, :due_on, :date
    add_column :school_bills, :drafted_at, :timestamptz
    add_column :school_bills, :issued_at, :timestamptz
    add_reference :school_bills, :client, index: false
    add_reference :school_bills, :issued_by, index: false
    add_index :school_bills, %i[school_id academic_year_id period_index family_id], unique: true, algorithm: :concurrently,
              where: "kind = 'period' AND family_id IS NOT NULL", name: "index_school_bills_one_per_family_period"
    add_index :school_bills, %i[school_id academic_year_id period_index], unique: true, algorithm: :concurrently,
              where: "kind = 'period' AND payer = 'school'", name: "index_school_bills_one_per_school_period"

    add_column :school_bill_lines, :rid, :string
    add_column :school_bill_lines, :note, :string
    add_reference :school_bill_lines, :credit_note, index: false

    add_column :finance_settings, :school_bill_draft_days, :integer, null: false, default: 7
    add_column :finance_settings, :school_bill_start_rule, :string, null: false, default: "prorate"
  end
end
