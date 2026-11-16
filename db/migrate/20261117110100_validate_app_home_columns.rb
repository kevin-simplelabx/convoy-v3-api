# Validates the foreign keys added by AddAppHomeColumns.
class ValidateAppHomeColumns < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :app_notifications, :dependants
    validate_foreign_key :app_notifications, :notices
  end
end
