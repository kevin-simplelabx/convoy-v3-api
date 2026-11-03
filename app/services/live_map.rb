# Live Map: every bus now — on a trip, available or offline — from the last report of its device, the run it is on and
# what was recorded at the stops so far.
module LiveMap
  # No report for this long = Offline (the bus stays on the map at its last position).
  OFFLINE_AFTER = 15.minutes
  # ETA to the next point: straight line at this speed (until a routing engine gives road times).
  ETA_SPEED_KMH = 30
  # Runs of these statuses are not driven.
  NOT_DRIVEN = %w[cancelled removed skipped].freeze

  module_function

  # Runs of the vehicles around a time (yesterday and today, for runs past midnight), with what the board needs.
  def runs_around(vehicle_ids, now)
    TripOccurrence.where(vehicle_id: vehicle_ids, date: (now.to_date - 1)..now.to_date).where.not(status: NOT_DRIVEN)
                  .includes(:client, :driver, :operator_driver, :vehicle, :stop_events, trip: :stops, trip_run: :times,
                                                                                         school_route: :stops)
                  .order(:starts_at).to_a
  end

  # The run a vehicle is on at a time: started (by the driver, or its start time passed) and not ended.
  def run_now(runs, now) = runs.find { |r| (r.started_at || r.starts_at) <= now && r.ends_at > now && r.ended_at.nil? }

  def eta_minutes(from, to) = (Geo.metres(from, to) / 1000.0 / ETA_SPEED_KMH * 60).ceil

  # A run's planned minute (after midnight of its date) as a time.
  def at_minute(occ, minute) = minute && (occ.date.in_time_zone + minute.minutes)
end
