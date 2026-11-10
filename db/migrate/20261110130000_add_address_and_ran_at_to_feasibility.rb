# Feasibility Studies: the address OneMap found for a prospect school's postal code (place.address) and when a scenario
# last ran (Run at).
class AddAddressAndRanAtToFeasibility < ActiveRecord::Migration[8.1]
  def change
    add_column :feasibility_studies, :prospect_address, :string
    add_column :feasibility_scenarios, :ran_at, :datetime
  end
end
