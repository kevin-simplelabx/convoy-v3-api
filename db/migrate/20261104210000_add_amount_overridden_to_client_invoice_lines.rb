# Client Invoices: a trip line whose amount (and quantity) was typed on the draft keeps it; the runs' total stays
# worked out from the runs for checking.
class AddAmountOverriddenToClientInvoiceLines < ActiveRecord::Migration[8.1]
  def change
    add_column :client_invoice_lines, :amount_overridden, :boolean, null: false, default: false
  end
end
