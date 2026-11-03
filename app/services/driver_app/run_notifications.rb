# Bell lines for drivers when their trips change, for runs today and tomorrow that have not started (the Drive tabs;
# further out the run shows as New when opened). Sync collects what it inserted, changed and removed, then `flush`:
#   a run that gains a driver       → run_assigned to them
#   a run that loses its driver     → run_unassigned (another driver took it) to the old one
#   a new time or bus, same driver  → run_changed
#   a run no longer planned         → run_removed
# Office cancel / restore and a new bus from a time (vehicle switch) are class methods.
module DriverApp
  class RunNotifications
    DRIVER = %i[driver_id operator_driver_id].freeze

    def initialize(now: Time.current)
      @now = now
      @changes = []
    end

    def self.window?(date, starts_at, now = Time.current) = date.between?(now.to_date, now.to_date + 1) && starts_at > now

    def inserted(company_id, ids_and_rows)
      ids_and_rows.each do |id, row|
        @changes << { company_id:, id:, date: row.date, after: pick(row.to_h) } if self.class.window?(row.date, row.starts_at, @now)
      end
    end

    def updated(occ, attrs) = changed(occ, occ.attributes.symbolize_keys, attrs)

    # A run's driver, time or bus before and after a change.
    def changed(occ, before, after)
      return unless self.class.window?(occ.date, after[:starts_at], @now)

      @changes << { company_id: occ.company_id, id: occ.id, date: occ.date, before: pick(before), after: pick(after) }
    end

    def removed(occ)
      return unless self.class.window?(occ.date, occ.starts_at, @now) && (occ.driver_id || occ.operator_driver_id)

      @changes << { company_id: occ.company_id, id: occ.id, date: occ.date, before: pick(occ.attributes.symbolize_keys),
                    source: occ.slice(:trip_id, :school_route_id, :trip_label), gone: true }
    end

    def flush
      return if @changes.empty?

      runs = TripOccurrence.where(id: @changes.reject { it[:gone] }.map { it[:id] }).includes(:trip, :vehicle, school_route: { plan: :school }).index_by(&:id)
      titles = removed_titles
      rows = @changes.flat_map { |c| lines(c.merge(title: c[:gone] ? titles[c[:source].values_at("trip_id", "school_route_id")] || c[:source]["trip_label"] : nil), runs[c[:id]]) }
      DriverNotification.insert_all!(rows) if rows.any?
    end

    # The office cancelled a run, or brought it back.
    def self.cancelled(occ, restored: false)
      return unless window?(occ.date, occ.starts_at) && (occ.driver_id || occ.operator_driver_id)

      text = restored ? "is back on" : "was cancelled"
      DriverNotification.create!(company_id: occ.company_id, driver_id: occ.driver_id, operator_driver_id: occ.operator_driver_id,
                                 kind: restored ? "run_changed" : "run_cancelled", title: restored ? "Trip back on" : "Trip cancelled",
                                 body: "#{title_of(occ)} #{when_text(occ)} #{text}.", occurrence_id: occ.id, occurrence_date: occ.date)
    end

    # A default driver entry that puts the driver on a bus from later today or tomorrow.
    def self.vehicle_switch(entry, now: Time.current)
      starts_at = entry.starts_on.in_time_zone + entry.start_time.minutes
      return unless entry.driver_id && window?(entry.starts_on, starts_at, now)

      day = entry.starts_on == now.to_date ? "today" : "tomorrow"
      DriverNotification.create!(company_id: entry.company_id, driver_id: entry.driver_id, kind: "vehicle_switch", title: "Vehicle switch #{day}",
                                 body: "Switch to #{entry.vehicle.plate} from #{entry.start_time_hm} #{day}. Do the handover inspection before you take it.",
                                 vehicle_id: entry.vehicle_id)
    end

    def self.title_of(occ) = occ.school_route&.title || occ.trip&.title || occ.trip_label

    def self.when_text(occ)
      day = if occ.date == Date.current then "today" elsif occ.date == Date.current + 1 then "tomorrow" else occ.date.strftime("%a %-d %b") end
      "#{day}, #{occ.start_time_hm}"
    end

    private

    def pick(h) = h.slice(:driver_id, :operator_driver_id, :starts_at, :vehicle_id, :replacement_id)

    # [trip_id, school_route_id] => title, for runs that are gone (loaded together).
    def removed_titles
      sources = @changes.select { it[:gone] }.map { it[:source] }
      trips = Trip.with_discarded.where(id: sources.filter_map { it["trip_id"] }).pluck(:id, :title).to_h { |id, t| [ [ id, nil ], t ] }
      routes = SchoolRoute.where(id: sources.filter_map { it["school_route_id"] }).includes(plan: :school).to_h { [ [ nil, it.id ], it.title ] }
      trips.merge(routes)
    end

    def lines(change, occ)
      before = change[:before] || {}
      after = change[:after] || {}
      title = change[:title] || self.class.title_of(occ)
      at = occ ? self.class.when_text(occ) : nil
      was = before.slice(*DRIVER).compact
      now = after.slice(*DRIVER).compact
      out = []
      if change[:gone]
        out << line(was, "run_removed", "Trip removed", "#{title} on #{at_text(change, before)} is no longer planned.", change)
      elsif was != now
        out << line(now, "run_assigned", "New trip assigned", "#{title} on #{at}. Open it to see the stops.", change) if now.any?
        out << line(was, "run_unassigned", "Trip given to another driver", "#{title} on #{at} is now driven by another driver.", change) if was.any?
      elsif now.any? && (before[:starts_at] != after[:starts_at] || before[:vehicle_id] != after[:vehicle_id])
        what = before[:starts_at] == after[:starts_at] ? "is now on #{occ.vehicle&.plate}" : "now starts at #{occ.start_time_hm}"
        out << line(now, "run_changed", "Trip changed", "#{title} on #{at} #{what}.", change)
      end
      out.compact
    end

    def at_text(change, before) = "#{change[:date] == @now.to_date ? 'today' : 'tomorrow'}, #{before[:starts_at]&.in_time_zone&.strftime('%H:%M')}"

    def line(member, kind, title, body, change)
      return if member.empty?

      { company_id: change[:company_id], driver_id: member[:driver_id],
        operator_driver_id: member[:operator_driver_id], kind:, title:, body:, occurrence_id: change[:id], occurrence_date: change[:date],
        created_at: @now, updated_at: @now }
    end
  end
end
