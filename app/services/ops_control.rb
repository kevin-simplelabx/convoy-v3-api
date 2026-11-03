# Ops Control: a control-station view of every run whose first pick-up is in the next 2 hours, checked against the
# rules below so the duty team can call the driver before it goes wrong. Thresholds are fixed, as in Convoy OS.
module OpsControl
  # Board window: runs from 15 min before now (just ended) to first pick-ups 2 hours ahead.
  BEHIND = 15.minutes
  AHEAD = 2.hours
  # Rules (minutes): warning, then action.
  LOGIN = [ 20, 10 ].freeze    # driver not logged in to the app before the first pick-up
  START = [ 15, 5 ].freeze     # trip not started before the first pick-up
  ETA = [ 2, 5 ].freeze        # ETA to the first pick-up later than scheduled by more than
  MISS_AFTER = 2               # not at the first pick-up this long after the scheduled time (action)
  LATE_AFTER = 2               # reached the first pick-up later than this = late start
  LATE_SHOWN = 10              # the late-arrival warning stays this long after arriving
  GPS = [ 3, 6 ].freeze        # no GPS for (a started run)
  ESCALATE_AFTER = 3           # action alerts not acknowledged within this escalate to the Ops Manager
  NEAR_METRES = 1000           # "Driver is N m away but has not started"
  LOCK = 73_010                # advisory lock class (with the company id) for Sync

  module_function

  def rules
    { login_minutes: LOGIN, start_minutes: START, eta_late_minutes: ETA, miss_after_minutes: MISS_AFTER, late_after_minutes: LATE_AFTER,
      gps_minutes: GPS, escalate_after_minutes: ESCALATE_AFTER, window_ahead_minutes: AHEAD.in_minutes.to_i,
      window_behind_minutes: BEHIND.in_minutes.to_i }
  end

  # Runs on the board (and the ones Sync checks): with a bus (runs without one are the Scheduler's Unassigned), not
  # cancelled, first pick-up up to 2 hours ahead, not ended over 15 min ago.
  def runs(now)
    TripOccurrence.where(date: (now.to_date - 1)..now.to_date).where.not(status: LiveMap::NOT_DRIVEN).where.not(vehicle_id: nil)
                  .where("starts_at <= ? AND COALESCE(ended_at, ends_at) > ?", now + AHEAD, now - BEHIND)
  end

  INCLUDES = [ :client, :driver, :operator_driver, :stop_events, { vehicle: { live_position: :tracking_device }, trip: :stops,
                                                                    trip_run: :times, school_route: :stops } ].freeze
end
