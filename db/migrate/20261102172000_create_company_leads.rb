# Convoy Admin > Company Leads: people in the Convoy App asked their company to use Convoy (company_leads, written by
# the app: work email domain, the company name they typed, who to contact, their name only when they agreed). Convoy
# follows up offline per domain (company_lead_domains: status and a note).
class CreateCompanyLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :company_leads do |t|
      t.string :domain, null: false
      t.string :company_name, null: false
      t.string :contact
      t.string :named_name
      t.string :named_via
      t.string :source, null: false, default: "Convoy app"
      t.datetime :asked_at, null: false
      t.timestamps
    end
    add_index :company_leads, %i[domain asked_at]

    create_table :company_lead_domains do |t|
      t.string :domain, null: false, index: { unique: true }
      t.string :status, null: false, default: "new"
      t.text :note
      t.references :updated_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_check_constraint :company_lead_domains, "status IN ('new', 'contacted', 'demo', 'signed', 'lost')", name: "company_lead_domains_status"
  end
end
