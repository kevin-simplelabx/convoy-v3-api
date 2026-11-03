# Driver app geofence (dual trigger, decided 26/10/2026): the phone says at once when the bus enters or leaves a point's
# 30 m circle; the server confirms the arrival from the GPS (inside and slow, or inside long enough).
class AddGeofenceToStopEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :occurrence_stop_events, :geofence_entered_at, :datetime
    add_column :occurrence_stop_events, :geofence_exited_at, :datetime
  end
end
