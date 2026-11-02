class ValidateCompaniesCountrySetByForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :companies, :users
  end
end
