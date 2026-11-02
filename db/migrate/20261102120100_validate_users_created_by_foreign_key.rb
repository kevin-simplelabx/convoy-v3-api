class ValidateUsersCreatedByForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :users, :users
  end
end
