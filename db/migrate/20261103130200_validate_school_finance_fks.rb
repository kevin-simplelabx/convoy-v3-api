class ValidateSchoolFinanceFks < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :school_bills, :clients
    validate_foreign_key :school_bills, column: :issued_by_id
    validate_foreign_key :school_bill_lines, column: :credit_note_id
    validate_foreign_key :school_documents, column: :applied_bill_id
  end
end
