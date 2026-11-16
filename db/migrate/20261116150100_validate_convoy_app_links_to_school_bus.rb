class ValidateConvoyAppLinksToSchoolBus < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :bus_requests, :households
    validate_foreign_key :bus_requests, :dependants
    validate_foreign_key :bus_requests, :app_accounts
    validate_foreign_key :bus_requests, :school_bills, column: :registration_bill_id
    validate_foreign_key :families, :households
    validate_foreign_key :family_guardians, :household_members
    validate_foreign_key :family_riders, :dependants
    validate_foreign_key :school_riders, :dependants
  end
end
