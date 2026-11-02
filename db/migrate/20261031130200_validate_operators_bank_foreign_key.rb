class ValidateOperatorsBankForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :operators, :banks
  end
end
