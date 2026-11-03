# Where one run stands at a time for Ops Control — driver app, started, at the first pick-up, distance, last GPS, ETA — and
# the alerts it raises now (most severe first), as in Convoy OS.
module OpsControl
  class Check
    Hit = Data.define(:kind, :severity, :message)

    attr_reader :occ, :hits

    # session: the driver's current app sign-in (nil = not logged in); last_seen: when the driver was last in the app.
    def initialize(occ, now:, session:, last_seen:)
      @occ = occ
      @now = now
      @session = session
      @last_seen = last_seen
      @hits = done? ? [] : find_hits.sort_by { -it.severity }
    end

    def severity = hits.first&.severity.to_i
    def first_pickup_at = @occ.starts_at
    def done? = @occ.ended_at.present? || @occ.completed? || @occ.ends_at <= @now
    def account? = (@occ.driver_id || @occ.operator_driver_id).present?
    def logged_in? = @session.present?
    def arrived_at = first_event&.arrived_at
    def arrived? = arrived_at.present?
    def started? = @occ.started_at.present? || arrived?
    def running? = started? && !done?
    def not_started? = !started? && !done?

    def ping_at = live&.recorded_at
    def ping_minutes = ping_at && ((@now - ping_at) / 60).floor

    def distance_m
      return nil unless live && first_stop&.dig(:lat)

      Geo.metres([ live.lat, live.lng ], [ first_stop[:lat], first_stop[:lng] ]).round
    end

    # ETA at the first pick-up: when it got there, or (started, fresh GPS) a straight line at 30 km/h from the last position.
    def eta_at
      return arrived_at if arrived?
      return nil unless started? && distance_m && !gps_lost?

      @now + LiveMap.eta_minutes([ live.lat, live.lng ], [ first_stop[:lat], first_stop[:lng] ]).minutes
    end

    def eta_late_minutes = eta_at && ((eta_at - first_pickup_at) / 60).round

    def state
      return "completed" if done?
      return "action_now" if severity == 2
      return "at_risk" if severity == 1
      return "on_route" if arrived?
      return "on_the_way" if started?

      logged_in? ? "ready" : "scheduled"
    end

    # Driver App column: not_logged_in / not_started / started / running / ended (no_account: no driver with an app).
    def app
      { status: app_status, started_at: @occ.started_at, ended_at: @occ.ended_at, signed_in_at: @session&.signed_in_at, last_seen_at: @last_seen }
    end

    # GPS column: at_drop_off (ended), no_signal, on_route (stops reached k of n), or the distance to the first pick-up.
    def gps
      stops = planned.size
      reached = @occ.stop_events.to_a.count { |e| e.arrived_at || e.skipped }
      { status: gps_status, last_ping_at: ping_at, distance_m: arrived? || done? ? nil : distance_m, stops_reached: reached, stops: }
    end

    def route_text
      names = planned.map { it[:name] }
      names.size > 1 ? "#{names.first} to #{names.last}" : names.first
    end

    private

    def app_status
      return "ended" if done?
      return "running" if arrived?
      return "started" if started?
      return "no_account" unless account?

      logged_in? ? "not_started" : "not_logged_in"
    end

    def gps_status
      return "at_drop_off" if done?
      return "no_signal" if ping_at.nil? || gps_lost?

      arrived? ? "on_route" : "to_first_pickup"
    end

    def live = @occ.vehicle&.live_position
    def planned = @planned ||= TripHistory.planned_stops(@occ)
    def first_stop = planned.first
    def first_event = @occ.stop_events.min_by(&:position)
    def gps_lost? = ping_minutes.to_i >= GPS[0]
    def mins(seconds) = [ (seconds / 60.0).round, 1 ].max
    def level(value, pair) = value >= pair[1] ? 2 : 1

    def find_hits
      s = first_pickup_at
      to_go = (s - @now) / 60.0
      list = []
      if arrived?
        late = arrived_at - s
        if late > LATE_AFTER * 60 && @now < arrived_at + LATE_SHOWN.minutes
          list << Hit.new("late", 1, "Reached first pick-up #{mins(late)} min late")
        end
      else
        if account? && !logged_in? && to_go <= LOGIN[0]
          list << Hit.new("login", to_go <= LOGIN[1] ? 2 : 1, "Driver not logged in to the Convoy Driver app")
        end
        if !started? && to_go <= START[0]
          text = to_go.negative? ? "Trip not started. #{mins(-to_go * 60)} min past first pick-up" : "Trip not started. First pick-up in #{mins(to_go * 60)} min"
          text += ". Driver is #{distance_m} m away but has not started" if distance_m && distance_m < NEAR_METRES
          list << Hit.new("start", to_go <= START[1] ? 2 : 1, text)
        end
        if started? && (late = eta_late_minutes) && late > ETA[0]
          list << Hit.new("eta", level(late, [ ETA[0], ETA[1] + 1 ]), "ETA #{eta_at.strftime('%H:%M')}, #{late} min late for first pick-up")
        end
        list << Hit.new("miss", 2, "Not at first pick-up. #{mins(-to_go * 60)} min late") if to_go <= -MISS_AFTER
      end
      if started? && ping_minutes && ping_minutes >= GPS[0]
        list << Hit.new("gps", ping_minutes >= GPS[1] ? 2 : 1, "No GPS for #{ping_minutes} min")
      end
      list
    end
  end
end
