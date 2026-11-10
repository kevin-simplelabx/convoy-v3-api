# School Bus families: codes are numbered per school (FAM-0001 is each school's first family, as the prototype's famNext),
# so a code is unique per school, not per company. The new index goes in first, so uniqueness never drops.
class ScopeFamilyCodesToSchool < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :families, %i[school_id code], unique: true, algorithm: :concurrently
    remove_index :families, %i[company_id code], unique: true, algorithm: :concurrently
  end
end
