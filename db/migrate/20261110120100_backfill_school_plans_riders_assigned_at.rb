# AM plans adopted before riders_assigned_at existed wrote their PUDO points at adoption, so they count as applied.
# Scheduled AM plans (starting after today) stay empty: the daily job applies them on their start day. Data only.
class BackfillSchoolPlansRidersAssignedAt < ActiveRecord::Migration[8.1]
  def up
    # Data only on a small table (a few plans per school); no lock beyond the rows updated.
    safety_assured do
      execute(<<~SQL.squish)
        UPDATE school_plans SET riders_assigned_at = COALESCE(adopted_at, updated_at)
        WHERE session = 'am' AND in_use AND effective_from <= CURRENT_DATE AND riders_assigned_at IS NULL
      SQL
    end
  end

  def down; end
end
