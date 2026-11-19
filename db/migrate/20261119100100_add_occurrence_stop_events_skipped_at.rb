# Convoy Driver app parity (19/11/2026): when a point was skipped on the road ("Skipped: 07:41" in the stop list). Null
# for a point skipped in Edit Route until the bus passes it.
class AddOccurrenceStopEventsSkippedAt < ActiveRecord::Migration[8.1]
  def change
    add_column :occurrence_stop_events, :skipped_at, :datetime
  end
end
