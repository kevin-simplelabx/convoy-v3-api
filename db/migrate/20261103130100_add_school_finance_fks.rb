class AddSchoolFinanceFks < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :school_bills, :clients, validate: false, on_delete: :nullify
    add_foreign_key :school_bills, :users, column: :issued_by_id, validate: false
    add_foreign_key :school_bill_lines, :school_documents, column: :credit_note_id, validate: false, on_delete: :nullify
    add_foreign_key :school_documents, :school_bills, column: :applied_bill_id, validate: false, on_delete: :nullify
  end
end
