# Prospect schools placed before prospect_address existed take the address kept in postal_geocodes; scenarios that
# already have a result take their last update as the run time. Data only, small tables.
class BackfillFeasibilityProspectAddress < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute(<<~SQL.squish)
        UPDATE feasibility_studies s SET prospect_address = g.address
        FROM postal_geocodes g
        WHERE g.country = 'SG' AND g.postal = s.prospect_postal AND g.found AND s.prospect_address IS NULL
      SQL
      execute("UPDATE feasibility_scenarios SET ran_at = updated_at WHERE result IS NOT NULL AND ran_at IS NULL")
    end
  end

  def down; end
end
