# School Bus › Year Setup › Payment & Refund Policy: versions per school, each in use from its effective date (when fares
# are due, late charges, reminders, withdrawal and refunds, change of address, deposit and fees, acknowledgement), and
# the school's Payment Methods (how parents may pay in the Convoy App, admin fees, which account receives the money).
class CreateSchoolPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :school_policy_versions do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: false
      t.integer :version, null: false
      t.date :effective_on, null: false
      t.string :due_rule, null: false, default: "before"
      t.integer :due_days_before, null: false, default: 14
      t.integer :due_day, null: false, default: 1
      t.string :late_type, null: false, default: "flat"
      t.decimal :late_flat, precision: 12, scale: 2
      t.decimal :late_pct, precision: 5, scale: 2
      t.decimal :late_cap, precision: 12, scale: 2
      t.integer :late_grace_days, null: false, default: 7
      t.integer :late_flag_days, null: false, default: 30
      t.integer :withdrawal_notice, null: false, default: 1
      t.string :withdrawal_unit, null: false, default: "months"
      t.string :refund_basis, null: false, default: "days"
      t.string :refund_method, null: false, default: "credit"
      t.integer :refund_within_days, null: false, default: 30
      t.decimal :withdrawal_fee, precision: 12, scale: 2
      t.integer :address_notice_days, null: false, default: 14
      t.string :address_start, null: false, default: "any"
      t.integer :address_max_days, null: false, default: 90
      t.decimal :deposit_amount, precision: 12, scale: 2, null: false, default: 0
      t.string :deposit_return, null: false, default: "offset"
      t.decimal :registration_fee, precision: 12, scale: 2, null: false, default: 0
      t.boolean :ack_required, null: false, default: true
      t.boolean :ack_reaccept, null: false, default: true
      t.text :ack_text
      t.references :published_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
    add_index :school_policy_versions, %i[school_id version], unique: true
    add_index :school_policy_versions, %i[school_id effective_on]

    create_table :policy_reminders do |t|
      t.references :school_policy_version, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.integer :position, null: false
      t.string :timing, null: false
      t.integer :days, null: false, default: 0
      t.boolean :email, null: false, default: false
      t.boolean :whatsapp, null: false, default: false
      t.boolean :app, null: false, default: false
      t.string :email_subject
      t.text :email_body
      t.text :whatsapp_body
      t.string :app_title
      t.string :app_body
    end
    add_index :policy_reminders, %i[school_policy_version_id position]

    create_table :school_payment_methods do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :school, null: false, foreign_key: true, index: { unique: true }
      %w[bank paynow card].each do |m|
        t.boolean :"#{m}_on", null: false, default: m != "card"
        t.string :"#{m}_fee_kind", null: false, default: "none"
        t.decimal :"#{m}_fee", precision: 12, scale: 2
      end
      t.boolean :own_account, null: false, default: false
      t.references :bank, foreign_key: true, index: false
      t.string :account_number
      t.string :account_name
      t.string :paynow_id
      t.references :updated_by, foreign_key: { to_table: :users }, index: false
      t.timestamps
    end
  end
end
