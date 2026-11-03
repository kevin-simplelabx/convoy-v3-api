# The Driver app's GPS profile, the same for every company (decided 26/10/2026; replaces the old per-company settings):
# best accuracy, a point every 5 s or 10 m moved, a heartbeat every 5 minutes when standing still, a 30 m geofence on each
# point. The server confirms an arrival when the bus is inside the circle and slow, or inside long enough.
module DriverApp
  module Gps
    PROFILE = { accuracy: "best", interval_seconds: 5, distance_filter_m: 10, heartbeat_seconds: 300, geofence_radius_m: 30,
                arrive_countdown_seconds: 10, leave_countdown_seconds: 10, after_trip_minutes: 15, max_points: 500 }.freeze
    RADIUS_M = 30
    SLOW_KMH = 5
    DWELL_SECONDS = 15
    MAX_AGE = 48.hours

    module_function

    # Live Map's GPS signal from the phone's accuracy (metres).
    def signal(accuracy_m)
      return if accuracy_m.nil?

      if accuracy_m <= 20 then "good"
      elsif accuracy_m <= 50 then "fair"
      else "poor"
      end
    end
  end
end
