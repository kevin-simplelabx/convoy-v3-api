# School Bus › School Finance › Operator Payments: each operator's pay run for a school's month — route pay worked out
# live until Ops sends it to Finance (then the route pay, routes and the replacement lines are kept), the lines Ops adds
# (deductions and additions, with files), maker-checker (sent, sent back, approved), the operator's invoice number, and
# the payments made here, which give it a Payment Voucher (PV). Approved runs may instead be paid in an Operator Payments batch.
class CreateSchoolPayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :school_payouts do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.date :month, null: false
      t.references :operator, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.decimal :base, precision: 12, scale: 2
      t.integer :routes_count
      t.jsonb :auto_lines, null: false, default: []
      t.string :invoice_number
      t.references :prepared_by, foreign_key: { to_table: :users }, index: false
      t.references :sent_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :sent_at
      t.references :returned_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :returned_at
      t.references :approved_by, foreign_key: { to_table: :users }, index: false
      t.timestamptz :approved_at
      t.string :voucher_number
      t.date :voucher_on
      t.timestamps
    end
    add_index :school_payouts, %i[school_id month operator_id], unique: true
    add_index :school_payouts, %i[company_id status]

    create_table :school_payout_adjustments do |t|
      t.references :school_payout, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.integer :sign, null: false
      t.date :adj_on, null: false
      t.string :route_label
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.text :reason, null: false
      t.references :paired_operator, foreign_key: { to_table: :operators }, index: false
      t.bigint :pair_id
      t.references :created_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end

    create_table :school_payout_files do |t|
      t.references :school_payout_adjustment, null: false, foreign_key: { on_delete: :cascade }
      t.string :file, null: false
      t.string :name
      t.timestamps
    end

    create_table :school_payout_payments do |t|
      t.references :school_payout, null: false, foreign_key: { on_delete: :cascade }
      t.date :paid_on, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :method, null: false
      t.string :reference
      t.references :recorded_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
  end
end
