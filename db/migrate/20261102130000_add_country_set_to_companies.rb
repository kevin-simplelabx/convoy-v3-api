# Company Settings > Country: when (and by whom) the company's country was confirmed. Once set it is locked; a change
# is a company_country_requests row that Convoy approves.
class AddCountrySetToCompanies < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :companies, :country_set_at, :datetime
    add_reference :companies, :country_set_by, index: { algorithm: :concurrently }
    add_foreign_key :companies, :users, column: :country_set_by_id, validate: false
  end
end
