# Convoy Driver app (API-ISSUES #16): on a sub-contracted run whose main contractor wants its own driver app, the driver
# picks after Start to stay on Convoy Driver App or continue on the contractor's app, and when.
class AddTripOccurrencesContractorAppChoice < ActiveRecord::Migration[8.1]
  def up
    # safety_assured: the partitioned parent can't take NOT VALID constraints; new columns are NULL (quick).
    safety_assured do
      execute <<~SQL
        ALTER TABLE trip_occurrences
          ADD COLUMN contractor_app_choice varchar,
          ADD COLUMN contractor_app_chosen_at timestamptz
      SQL
    end
  end

  def down
    safety_assured { execute "ALTER TABLE trip_occurrences DROP COLUMN contractor_app_choice, DROP COLUMN contractor_app_chosen_at" }
  end
end
