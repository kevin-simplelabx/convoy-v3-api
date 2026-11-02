# Company Settings > Request a Country Change: a company asks Convoy to move it to another country (with a reason);
# a Convoy Admin approves (the company's country changes) or declines, or the company withdraws. One pending request
# per company; the rows are the change history.
class CreateCompanyCountryRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :company_country_requests do |t|
      t.references :company, null: false, foreign_key: true, index: false
      t.string :from_country, null: false
      t.string :to_country, null: false
      t.text :reason, null: false
      t.string :status, null: false, default: "pending"
      t.references :requested_by, foreign_key: { to_table: :users }
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at
      t.timestamps
    end
    add_index :company_country_requests, %i[company_id created_at]
    add_index :company_country_requests, :company_id, unique: true, where: "status = 'pending'", name: "index_company_country_requests_one_pending"
    add_index :company_country_requests, %i[status created_at]
    add_check_constraint :company_country_requests, "status IN ('pending', 'approved', 'declined', 'withdrawn')",
                         name: "company_country_requests_status"
  end
end
