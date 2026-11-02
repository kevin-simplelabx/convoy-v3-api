# Client Invoices > Record Payment (what a client paid on an issued invoice) and Email (sends are recorded only).
class CreateClientInvoicePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :client_invoice_payments do |t|
      t.references :client_invoice, null: false, foreign_key: true
      t.date :paid_on, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :method, null: false
      t.string :reference
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_check_constraint :client_invoice_payments, "amount > 0", name: "client_invoice_payments_amount"

    create_table :client_invoice_sends do |t|
      t.references :client_invoice, null: false, foreign_key: true
      t.string :to_emails, array: true, null: false, default: []
      t.string :cc_emails, array: true, null: false, default: []
      t.references :sent_by, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
