# Finance > Finance Settings: one row per company. GST (on, rate, before / including, registration no.), operator pay
# run approval (one person / maker-checker) with who can prepare and approve (finance_approvers), what documents show
# (brand), where clients pay (bank, account, PayNow, payment note) and the prefix of each document type. New documents
# use these settings; documents already issued keep a snapshot. Can be locked.
class CreateFinanceSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :finance_settings do |t|
      t.references :company, null: false, foreign_key: true, index: { unique: true }
      t.boolean :gst_on, null: false, default: false
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 9
      t.string :gst_mode, null: false, default: "excl"
      t.string :gst_reg_no
      t.string :approval, null: false, default: "single"
      t.string :brand_name
      t.string :brand_uen
      t.text :brand_address
      t.string :brand_phone
      t.string :brand_email
      t.string :brand_note, default: "Thank you for riding with us."
      t.references :bank, foreign_key: true
      t.string :account_number
      t.string :account_name
      t.string :paynow
      t.string :payment_note, default: "Please pay by the due date and quote the invoice number."
      t.string :prefix_inv, null: false, default: "INV"
      t.string :prefix_cn, null: false, default: "CN"
      t.string :prefix_dn, null: false, default: "DN"
      t.string :prefix_rcp, null: false, default: "RCP"
      t.string :prefix_pv, null: false, default: "PV"
      t.string :prefix_pn, null: false, default: "PN"
      t.string :prefix_pb, null: false, default: "PB"
      t.datetime :locked_at
      t.references :locked_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_check_constraint :finance_settings, "gst_mode IN ('excl', 'incl')", name: "finance_settings_gst_mode"
    add_check_constraint :finance_settings, "approval IN ('single', 'maker')", name: "finance_settings_approval"

    create_table :finance_approvers do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true
      t.boolean :can_prepare, null: false, default: true
      t.boolean :can_approve, null: false, default: false
      t.timestamps
    end
    add_index :finance_approvers, %i[company_id user_id], unique: true
  end
end
