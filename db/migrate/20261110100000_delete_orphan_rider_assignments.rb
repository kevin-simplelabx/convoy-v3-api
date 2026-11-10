# Deletes rider assignments left behind by an Unlink / Archive of a stop (the school no longer uses the point's stop, or
# the stop is archived). Unlink and Archive now remove them in the same transaction. Not reversible (data only).
class DeleteOrphanRiderAssignments < ActiveRecord::Migration[8.1]
  def up
    # Data only: deletes rows that point at stops nothing uses any more; the table is small (one row per assigned rider).
    safety_assured do
      execute(<<~SQL.squish)
        DELETE FROM rider_assignments ra
        USING stop_points sp
        WHERE sp.id = ra.stop_point_id
          AND (EXISTS (SELECT 1 FROM stops s WHERE s.id = sp.stop_id AND s.discarded_at IS NOT NULL)
               OR NOT EXISTS (SELECT 1 FROM school_stops ss WHERE ss.stop_id = sp.stop_id AND ss.school_id = ra.school_id))
      SQL
    end
  end

  def down; end
end
