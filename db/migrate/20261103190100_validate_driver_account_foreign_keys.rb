class ValidateDriverAccountForeignKeys < ActiveRecord::Migration[8.1]
  def up
    validate_foreign_key :drivers, :driver_accounts
    validate_foreign_key :operator_drivers, :driver_accounts

    # safety_assured: one-off backfill of the new columns on two small tables (a company has tens of drivers).
    safety_assured do
      %w[drivers operator_drivers].each do |table|
        execute "UPDATE #{table} SET joined_at = responded_at WHERE status = 'active' AND joined_at IS NULL"
        execute "UPDATE #{table} SET left_at = responded_at WHERE status = 'past' AND left_at IS NULL"
      end
    end
  end

  def down; end
end
