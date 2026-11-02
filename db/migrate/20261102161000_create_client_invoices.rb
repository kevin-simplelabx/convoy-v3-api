# Finance > Client Invoices. Clients get their billing terms (payment days, default PO, late-cancel cut-off hours).
# An invoice (or a credit note against one) bills a client or a site billed as its own entity, with a snapshot of who
# it is billed to and of the GST settings. Lines are trips (one per trip, with the runs it bills), late cancellations
# (runs billed in full, each can be waived) or manual lines. A run is on at most one invoice that is not void
# (client_invoice_line_runs.active + partial unique index); runs keep (occurrence_id, occurrence_date).
class CreateClientInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :payment_terms_days, :integer
    add_column :clients, :default_po, :string
    add_column :clients, :late_cancel_hours, :integer, null: false, default: 24

    create_table :client_invoices do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :kind, null: false, default: "invoice"
      t.string :number
      t.string :status, null: false, default: "draft"
      t.references :client, null: false, foreign_key: true
      t.references :client_site, foreign_key: true
      t.references :invoice, foreign_key: { to_table: :client_invoices }
      t.references :trip, foreign_key: true
      t.string :bill_to_name
      t.string :bill_to_uen
      t.text :bill_to_address
      t.string :attention
      t.string :po
      t.date :issued_on
      t.integer :terms_days, null: false, default: 30
      t.date :due_on
      t.date :period_from
      t.date :period_to
      t.boolean :gst_on, null: false, default: false
      t.decimal :gst_rate, precision: 5, scale: 2, null: false, default: 0
      t.string :gst_mode, null: false, default: "excl"
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :gst, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.text :reason
      t.text :notes
      t.references :created_by, foreign_key: { to_table: :users }
      t.datetime :issued_at
      t.references :issued_by, foreign_key: { to_table: :users }
      t.datetime :voided_at
      t.references :voided_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :client_invoices, %i[company_id kind status]
    add_index :client_invoices, %i[company_id number], unique: true, where: "number IS NOT NULL"
    add_check_constraint :client_invoices, "kind IN ('invoice', 'credit_note')", name: "client_invoices_kind"
    add_check_constraint :client_invoices, "status IN ('draft', 'issued', 'void')", name: "client_invoices_status"

    create_table :client_invoice_lines do |t|
      t.references :client_invoice, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :source, null: false, default: "manual"
      t.references :trip, foreign_key: true
      t.string :ref
      t.string :description, null: false
      t.text :details
      t.string :period_text
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.decimal :unit_price, precision: 12, scale: 2
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :client_invoice_lines, "source IN ('trip', 'late_cancel', 'manual')", name: "client_invoice_lines_source"

    create_table :client_invoice_line_runs do |t|
      t.references :client_invoice_line, null: false, foreign_key: true
      t.bigint :occurrence_id, null: false
      t.date :occurrence_date, null: false
      t.integer :start_time
      t.string :trip_label
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.boolean :waived, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :client_invoice_line_runs, %i[occurrence_id occurrence_date], unique: true, where: "active", name: "index_client_invoice_line_runs_billed_once"
  end
end
