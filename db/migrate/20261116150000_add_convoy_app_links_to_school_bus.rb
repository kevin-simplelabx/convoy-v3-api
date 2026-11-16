# Convoy App Phase 4a: School Bus requests sent from the app and the tenant records they lead to.
# bus_requests: who sent it (household, child, account), a drop-off point when it differs from the pick-up, the CCA bus
# start, the Agree switch, the registration fee bill, and new_home: a Change of Address that also moves the Family's home
# keeps the typed address (block, street, floor, unit, postal) to apply when the company confirms it (snapshot).
# families / family_guardians / family_riders / school_riders: the app ids they were copied from when OS accepted.
class AddConvoyAppLinksToSchoolBus < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_column :bus_requests, :household_id, :bigint
    add_column :bus_requests, :dependant_id, :bigint
    add_column :bus_requests, :app_account_id, :bigint
    add_column :bus_requests, :registration_bill_id, :bigint
    add_column :bus_requests, :dropoff_address, :string
    add_column :bus_requests, :dropoff_postal, :string
    add_column :bus_requests, :dropoff_lat, :decimal, precision: 10, scale: 7
    add_column :bus_requests, :dropoff_lng, :decimal, precision: 10, scale: 7
    add_column :bus_requests, :cca_from, :date
    add_column :bus_requests, :new_home, :jsonb
    add_column :bus_requests, :terms_agreed_at, :timestamptz
    add_index :bus_requests, :household_id, algorithm: :concurrently
    add_index :bus_requests, :dependant_id, algorithm: :concurrently
    add_index :bus_requests, :app_account_id, algorithm: :concurrently
    add_index :bus_requests, :registration_bill_id, algorithm: :concurrently
    add_foreign_key :bus_requests, :households, on_delete: :nullify, validate: false
    add_foreign_key :bus_requests, :dependants, on_delete: :nullify, validate: false
    add_foreign_key :bus_requests, :app_accounts, on_delete: :nullify, validate: false
    add_foreign_key :bus_requests, :school_bills, column: :registration_bill_id, on_delete: :nullify, validate: false

    add_column :families, :household_id, :bigint
    add_index :families, %i[school_id household_id], unique: true, where: "household_id IS NOT NULL", name: "index_families_one_per_household",
                                                     algorithm: :concurrently
    add_index :families, :household_id, algorithm: :concurrently
    add_foreign_key :families, :households, on_delete: :nullify, validate: false

    add_column :family_guardians, :household_member_id, :bigint
    add_index :family_guardians, :household_member_id, algorithm: :concurrently
    add_foreign_key :family_guardians, :household_members, on_delete: :nullify, validate: false

    add_column :family_riders, :dependant_id, :bigint
    add_index :family_riders, :dependant_id, algorithm: :concurrently
    add_foreign_key :family_riders, :dependants, on_delete: :nullify, validate: false

    add_column :school_riders, :dependant_id, :bigint
    add_index :school_riders, :dependant_id, algorithm: :concurrently
    add_foreign_key :school_riders, :dependants, on_delete: :nullify, validate: false
  end
end
