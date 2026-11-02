# Send Invoices To: the people who get a client's (or a separately billed site's) invoice email. To and CC get the
# email; everyone ticked under Attention is printed as Attn on the invoice (a person may be Attention only, with no
# email). Finance reads them when it sends invoices.
class CreateClientBillingContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :client_billing_contacts do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.references :billable, polymorphic: true, null: false
      t.string :name
      t.string :email
      t.string :send_as, null: false, default: "to"
      t.boolean :attention, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :client_billing_contacts, :company_id
    add_index :client_billing_contacts, %i[billable_type billable_id email], unique: true, where: "email IS NOT NULL",
                                                                          name: "index_client_billing_contacts_unique_email"
    add_check_constraint :client_billing_contacts, "send_as IN ('to', 'cc')", name: "client_billing_contacts_send_as"
  end
end
