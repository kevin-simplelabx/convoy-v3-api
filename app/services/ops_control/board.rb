# The Ops Control board from the checks of Sync: KPIs, the action banner, tab counts, client filter and the rows
# (filtered by client / search / tab, sorted by first pick-up), each with its open alerts and who acknowledged them.
module OpsControl
  class Board
    TABS = {
      "needs_action" => ->(c) { c.severity.positive? }, "all" => ->(_c) { true }, "not_started" => ->(c) { c.not_started? },
      "running" => ->(c) { c.running? }, "ended" => ->(c) { c.done? }
    }.freeze
    BANNER = 3

    def initialize(checks, now: Time.current)
      @checks = checks
      @now = now
      @alerts = OpsAlert.open.where(occurrence_id: checks.map { it.occ.id }).includes(:acknowledged_by).group_by(&:occurrence_id)
    end

    def call(tab: "needs_action", client_id: nil, q: nil, sort: "asc")
      tab = TABS.key?(tab) ? tab : "needs_action"
      list = @checks.select { |c| client_id.blank? || c.occ.client_id == client_id.to_i }
      list = list.select { |c| matches?(c, q.to_s.strip.downcase) } if q.present?
      shown = list.select(&TABS[tab]).sort_by { |c| [ c.first_pickup_at.to_i * (sort == "desc" ? -1 : 1), -c.severity, c.occ.trip_label ] }
      { kpis:, banner:, tab:, counts: TABS.transform_values { |f| list.count(&f) }, clients:, rows: shown.map { |c| row(c) } }
    end

    private

    def matches?(c, q)
      o = c.occ
      [ o.vehicle&.plate, driver(o)&.dig(:name), o.decorate.title, o.trip_label, o.client&.name ].compact.any? { it.downcase.include?(q) }
    end

    def driver(o) = o.decorate.driver_info&.slice(:name, :phone)

    def row(c)
      o = c.occ
      open = @alerts[o.id] || []
      held = open.index_by { |a| [ a.kind, a.severity ] }
      acked = open.select(&:acknowledged_at).max_by(&:acknowledged_at)
      {
        id: o.id, key: o.decorate.key, date: o.date, trip_label: o.trip_label, title: o.decorate.title, client: o.client&.slice(:id, :name),
        route: c.route_text, vehicle_id: o.vehicle_id, plate: o.vehicle&.plate, driver: driver(o),
        first_pickup_at: c.first_pickup_at, ends_at: o.ends_at, timeline_from: c.first_pickup_at - START[0].minutes,
        state: c.state, severity: c.severity, arrived_at: c.arrived_at, app: c.app, gps: c.gps,
        eta: { at: c.eta_at, late_minutes: c.arrived? ? nil : c.eta_late_minutes },
        alerts: c.hits.map do |h|
          a = held[[ h.kind, h.severity ]]
          { id: a&.id, kind: h.kind, severity: h.severity, message: h.message, raised_at: a&.raised_at, acknowledged_at: a&.acknowledged_at,
            acknowledged_by: a&.acknowledged_by&.name, escalated: a&.escalated_at.present? }
        end,
        can_acknowledge: open.any? { it.acknowledged_at.nil? },
        acknowledged: acked && open.none? { it.acknowledged_at.nil? } ? { at: acked.acknowledged_at, by: acked.acknowledged_by&.name } : nil
      }
    end

    def kpis
      ahead = @now + AHEAD
      action = @checks.select { it.severity == 2 }
      unacked = @alerts.values.flatten.count { |a| a.action? && a.acknowledged_at.nil? }
      past = TripOccurrence.where(date: @now.to_date).where.not(status: LiveMap::NOT_DRIVEN).where.not(vehicle_id: nil).where(starts_at: ..@now)
      on_time = past.joins("JOIN occurrence_stop_events e ON e.occurrence_id = trip_occurrences.id AND e.occurrence_date = trip_occurrences.date " \
                           "AND e.position = 0")
                    .where("e.arrived_at <= trip_occurrences.starts_at + make_interval(mins => ?)", LATE_AFTER).count
      total = past.count
      {
        next_2_hours: @checks.count { it.first_pickup_at > @now && it.first_pickup_at <= ahead }, window_until: ahead,
        running: @checks.count(&:running?), action_now: action.size, unacknowledged: unacked,
        at_risk: @checks.count { it.severity == 1 },
        on_time_today: total.zero? ? nil : (on_time * 100.0 / total).round, on_time_count: on_time, started_today: total,
        late_today: total - on_time
      }
    end

    # Trips with action alerts nobody acknowledged, earliest first pick-up first.
    def banner
      trips = @checks.filter_map do |c|
        list = (@alerts[c.occ.id] || []).select { |a| a.action? && a.acknowledged_at.nil? }
        next if list.empty?

        hit = c.hits.find { |h| h.severity == 2 && list.any? { |a| a.kind == h.kind } }
        o = c.occ
        { occurrence_id: o.id, first_pickup_at: c.first_pickup_at, plate: o.vehicle&.plate, message: hit&.message || list.first.message,
          title: o.decorate.title, trip_label: o.trip_label, client: o.client&.name, route: c.route_text, raised_at: list.map(&:raised_at).min,
          escalated: list.any?(&:escalated_at), driver: driver(o) }
      end.sort_by { it[:first_pickup_at] }
      { count: trips.size, trips: trips.first(BANNER), more: [ trips.size - BANNER, 0 ].max }
    end

    def clients = @checks.filter_map { it.occ.client }.uniq.sort_by(&:name).map { it.slice(:id, :name) }
  end
end
