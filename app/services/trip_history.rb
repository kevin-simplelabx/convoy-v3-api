# Trip History: the record of every run that ran, was cancelled or was skipped (TripHistoryQuery lists them,
# TripHistory::Record builds one record, TripHistory::Correct corrects one). Values shown are the corrected ones when
# Correct Record changed them (the correction must be loaded).
module TripHistory
  OUTCOMES = {
    "completed" => { label: "Completed", tone: "success" },
    "incomplete" => { label: "Incomplete", tone: "warning" },
    "cancelled_by_client" => { label: "Cancelled by Client", tone: "neutral" },
    "cancelled_by_us" => { label: "Cancelled by Us", tone: "danger" },
    "skipped" => { label: "Skipped by Calendar", tone: "neutral" }
  }.freeze
  ON_TIME = { "on_time" => "On Time", "late" => "Late", "na" => "N/A" }.freeze
  DAY_NAMES = %w[Sun Mon Tue Wed Thu Fri Sat].freeze

  # Same rules as TripHistoryQuery::OUTCOME_SQL.
  def self.outcome(occ) = (occ.completed? && occ.correction&.outcome) || recorded_outcome(occ)

  def self.recorded_outcome(occ)
    case occ.status
    when "skipped" then "skipped"
    when "cancelled" then occ.cancelled_by_client? ? "cancelled_by_client" : "cancelled_by_us"
    else "completed"
    end
  end

  def self.corrected?(occ) = occ.correction.present?

  # Same rules as TripHistoryQuery::NEEDS_LOOK_SQL (notes, correction and summary must be loaded): a replacement, an issue,
  # a note, a correction, an incomplete run or speeding.
  def self.needs_look?(occ)
    occ.replacement_id.present? || occ.issue_reason.present? || occ.history_notes.any? || corrected?(occ) ||
      outcome(occ) == "incomplete" || occ.trip_summary&.overspeed_seconds.to_i.positive?
  end

  # Same rules as TripHistoryQuery#on_time_sql: late when a stop was reached more than on_time_minutes after plan;
  # N/A unless it ran to the end and arrival times are known (max_delay_minutes, kept by TripHistory::Punctuality).
  def self.on_time(occ, on_time_minutes)
    return "na" if outcome(occ) != "completed" || occ.max_delay_minutes.nil?

    occ.max_delay_minutes > on_time_minutes ? "late" : "on_time"
  end

  def self.driver_name(occ) = occ.correction&.driver_name || recorded_driver_name(occ)

  def self.recorded_driver_name(occ)
    occ.driver&.name || occ.operator_driver&.name || occ.driver_name.presence || occ.vehicle&.driver_name
  end

  # The vehicle used: { vehicle (nil when only a plate was given), plate }.
  def self.vehicle(occ)
    c = occ.correction
    c&.vehicle_plate ? { vehicle: c.vehicle, plate: c.vehicle_plate } : { vehicle: occ.vehicle, plate: occ.vehicle&.plate }
  end

  # What the driver app / telematics recorded at each stop (stop events must be loaded):
  # { position => { arrived_at, departed_at (minutes after midnight of the run's date), boarded, alighted, skipped } }.
  def self.recorded_stops(occ)
    occ.stop_events.to_h do |e|
      [ e.position, { arrived_at: run_minute(occ, e.arrived_at), departed_at: run_minute(occ, e.departed_at), boarded: e.boarded,
                      alighted: e.alighted, skipped: e.skipped } ]
    end
  end

  def self.run_minute(occ, time) = time && (occ.start_time + ((time - occ.starts_at) / 60.0).round)

  # Each stop, planned against what happened (corrected values first; `was` = the recorded value of a corrected field):
  # served (reached), skipped (passed with no one to pick up), delay_minutes, late, on_board after the stop.
  def self.stop_record(occ, on_time_minutes)
    recorded = recorded_stops(occ)
    on_board = 0
    planned_stops(occ).map do |s|
      fixed = occ.correction&.stop(s[:position])
      rec = recorded[s[:position]] || {}
      actual = STOP_FIELDS.to_h { |f| [ f, fixed && !fixed[f].nil? ? fixed[f] : rec[f] ] }
      served = !actual[:arrived_at].nil? || actual[:boarded].present?
      skipped = served && rec[:skipped] == true
      delay = served && !skipped && actual[:arrived_at] && s[:planned_minute] ? actual[:arrived_at] - s[:planned_minute] : nil
      on_board += actual[:boarded].to_i - actual[:alighted].to_i if served
      was = STOP_FIELDS.select { |f| fixed && !fixed[f].nil? }.to_h { |f| [ f, show(f, rec[f]) ] }
      s.merge(STOP_FIELDS.to_h { |f| [ f, show(f, actual[f]) ] })
       .merge(served:, skipped:, delay_minutes: delay, late: !delay.nil? && delay > on_time_minutes, on_board: served ? on_board : nil, was:)
    end
  end

  STOP_FIELDS = %i[arrived_at departed_at boarded alighted].freeze

  def self.show(field, value) = %i[arrived_at departed_at].include?(field) ? Clock.hm(value) : value

  # Riders carried: boarded at the stops when known, else the planned pax.
  def self.pax(occ)
    recorded = recorded_stops(occ)
    positions = recorded.keys | Array(occ.correction&.stops).map(&:position)
    known = positions.filter_map do |pos|
      fixed = occ.correction&.stop(pos)&.boarded
      fixed.nil? ? recorded.dig(pos, :boarded) : fixed
    end
    known.any? ? known.sum : occ.pax
  end

  # The run's stops in travel order with their planned times (the run's timetable, else the first pick-up time).
  def self.planned_stops(occ)
    if occ.school_route
      return occ.school_route.stops.each_with_index.map do |s, i|
        { position: i, name: s.name, use: nil, planned_time: s.scheduled_time_hm, planned_minute: s.scheduled_time, lat: s.lat, lng: s.lng }
      end
    end
    trip = occ.trip
    return [] unless trip

    times = occ.trip_run ? occ.trip_run.stop_minutes : []
    trip.stops_in(occ.trip_run&.direction || 1).each_with_index.map do |s, i|
      minute = times[i] || s.scheduled_time || (occ.start_time - occ.shift_minutes if i.zero?)
      minute += occ.shift_minutes if minute
      { position: i, name: s.name, use: s.use, planned_time: Clock.hm(minute), planned_minute: minute, lat: s.lat, lng: s.lng,
        note: s.driver_note }
    end
  end
end
